package Plift;

use strict;
use warnings;
use Moo;
use Class::Load ();
use Path::Tiny ();
use XML::LibXML::jQuery;
use Carp;
use Plift::Context;
use Digest::MD5 qw/ md5_hex /;
use namespace::clean;

our $VERSION = "0.15";

use constant {
    XML_DOCUMENT_NODE      => 9,
    XML_DOCUMENT_FRAG_NODE => 11,
    XML_DTD_NODE           => 14
};

has 'helper', is => 'ro';
has 'wrapper', is => 'ro';
has 'paths', is => 'rw', default => sub { ['.'] };
has 'snippet_namespaces', is => 'ro', default => sub { [] };
has 'plugins', is => 'ro', default => sub { [] };
has 'encoding', is => 'rw', default => 'UTF-8';
has 'debug', is => 'rw', default => sub { $ENV{PLIFT_DEBUG} };
has 'max_file_size', is => 'rw', default => 1024 * 1024;
has 'enable_cache', is => 'rw', default => 1;
has 'max_cached_files', is => 'rw', default => 50;

has '_cache', is => 'ro', default => sub { {} };



sub BUILD {
    my $self = shift;

    # builtin handlers
    my @components = qw/
        Handler::Include
        Handler::Wrap
        Handler::Render
        Handler::Snippet
        Handler::Meta
    /;

    # plugins
    push @components, map { /^\+/ ? $_ : 'Plugin::'.$_ } @{ $self->plugins };

    $self->load_components(@components);

    ## remove-if / remove-unless
    $self->hook('after_load_template', \&_after_load_template);
}

sub _after_load_template {
    my ($c, $dom) = @_;

    # remove-if/unless
    my $xpath =  join ' | ', map { ("./*[\@$_]", ".//*[\@$_]") }
                             map { ($_, "data-$_")  }
                             qw/ remove-if remove-unless /;

    foreach my $node ( @{ $dom->xfilter($xpath)->{nodes} }, @{ $dom->xfind($xpath)->{nodes} } ) {

        # remove-if
        if (exists $node->{'remove-if'} || exists $node->{'data-remove-if'} ) {

            if ($c->get($node->{'remove-if'} || $node->{'data-remove-if'})) {

                $node->unbindNode;
            } else {

                delete $node->{'remove-if'};
                delete $node->{'data-remove-if'};
            }
        }

        # remove-unless
        if (exists $node->{'remove-unless'} || exists $node->{'data-remove-unless'} ) {

            unless ($c->get($node->{'remove-unless'} || $node->{'data-remove-unless'})) {

                $node->unbindNode;
            } else {

                delete $node->{'remove-unless'};
                delete $node->{'data-remove-unless'};
            }
        }
    }
}


sub load_components {
    my $self = shift;

    # instantiate and init
    foreach my $name (@_) {

        my $class = $name =~ /^\+/ ? substr($name, 1)
                                   : __PACKAGE__.'::'.$name;

        my $plugin = Class::Load::load_class($class)->new;
        $plugin->register($self);
    }
}

sub has_template {
    my ($self, $name) = @_;
    return !! $self->_find_template_file($name, $self->paths);
}



sub template {
    my ($self, $name, $options) = @_;
    $options ||= {};

    # path copy for the load_template closure
    # this way we do not expose the engine nor the path to the context object
    my @paths = @{ delete $options->{paths} || $self->paths };
    my @ns    = @{ delete $options->{snippet_namespaces} || $self->snippet_namespaces };

    $options->{$_} ||= $self->$_ for qw/ helper wrapper encoding /;

    $options->{data_stack} = [delete $options->{data}]
        if defined $options->{data};

    Plift::Context->new(
        %$options,
        template => $name,
        handlers => [@{ $self->{handlers}}],
        load_template => sub {
            my ($ctx, $name) = @_;
            $self->_load_template($name, \@paths, $ctx)
        },
        load_snippet => sub {
            $self->_load_snippet(\@ns, @_);
        },
        run_hooks => sub {
            $self->run_hooks(@_);
        },
    );
}

sub process {
    my ($self, $template, $data, $schema) = @_;

    my $ctx = $self->template($template);

    $ctx->at($schema)
        if $schema;

    $ctx->render($data);
}

sub render {
    my $self = shift;
    $self->process(@_)->as_html;
}


sub add_handler {
    my ($self, $config) = @_;

    confess "missing handler callback"
        unless $config->{handler};

    confess "missing handler name"
        unless $config->{name};

    my @match;

    for my $key (qw/ tag attribute /) {
        $config->{$key} = [$config->{$key}]
            if defined $config->{$key} && !ref $config->{$key};
    }

    push(@match, map { ".//$_" } @{$config->{tag}})
        if $config->{tag};

    push(@match, map { ".//*[\@$_]" } @{$config->{attribute}})
        if $config->{attribute};

    push @match, $config->{xpath}
        if $config->{xpath};

    my $match = join ' | ', @match;

    printf STDERR "[Plift] Adding handler: $match\n"
        if $self->debug;

    # check config has one of tag/attribute/xpath
    confess "Invalid handler. Missing at least one binding criteria (tag, attribute or xpath)."
        unless $match;

    my $handler = {
        tag => $config->{tag},
        attribute => $config->{attribute},
        name => $config->{name},
        xpath => $match,
        sub => $config->{handler}
    };

    push @{$self->{handlers}}, $handler;
    $self->{handlers_by_name}->{$handler->{name}} = $handler;

    $self;
}

sub get_handler {
    my ($self, $name) = @_;
    $self->{handlers_by_name}->{$name};
}



my %hooks;
sub hook {
    my ($self, $step, $cb) = @_;

    croak "Usage: plift->hook(<step>, <callback>)"
        unless $step && $cb && ref $cb eq 'CODE';

    push @{$hooks{$step}}, $cb;
    $self;
}

sub run_hooks {
    my ($self, $step, $args) = @_;

    foreach my $cb (@{ $hooks{$step} || [] }) {
        $cb->(@{ $args || [] });
    }
}



sub _load_template {
    my ($self, $template, $paths, $ctx) = @_;

    my ($tpl_source, $tpl_etag, $tpl_file, $tpl_path, $cache_key);

    # inline template
    if (ref $template) {

        $tpl_source = $$template;
        $tpl_etag = md5_hex($tpl_source);
        $cache_key = 'inline:'.$tpl_etag;
    }

    # file template
    else {

        # add relative prefix
        # (only './foo' and '../foo' are considered relative, not plain 'foo')
        if (defined $ctx->{current_file} && $template =~ /^\.\.?\//) {
            my $current_file = $ctx->{current_file};
            my $current_path = $ctx->{current_path};
            my $prefix = $current_file->parent->relative($current_path);
            $template = "$prefix/$template"
                unless $prefix eq '.';
        }

        # resolve template file
        ($tpl_file, $tpl_path) = $self->_find_template_file($template, $paths);
        die sprintf "Can't find a template file for template '%s'. Tried:\n%s\n", $template, join(",\n", @$paths)
            unless $tpl_file;

        # update contex current file/path
        $ctx->{current_file} = $tpl_file;
        $ctx->{current_path} = $tpl_path;

        $tpl_etag = $tpl_file->stat->mtime;
        $cache_key = $tpl_file->stringify;
    }

    # cached template
    my $cache = $self->_cache;
    my $dom;

    # get from cache
    if ($self->enable_cache && (my $entry = $cache->{$cache_key})) {

        # cache hit
        if ($entry->{etag} eq $tpl_etag) {

            $dom = $entry->{dom}->clone->contents;
            $entry->{hits} += 1;
            $entry->{last_hit} = time;
            # printf STDERR "# Plift cache hit: '$tpl_file' => %d hits\n", $entry->{hits};
        }

        # invalidade cache entry
        else {
            delete $cache->{$cache_key};
        }
    }

    unless ($dom) {

        # max file size
        my $tpl_size = defined $tpl_file ? $tpl_file->stat->size : length $tpl_source;
        die sprintf("Template '%s' exceeds the max_file_size option! (%d > %d)\n", $cache_key, $tpl_size, $self->max_file_size)
            if $tpl_size > $self->max_file_size;

        # parse source
        if (defined $tpl_file) {
            $tpl_source = $ctx->encoding eq 'UTF-8' ? $tpl_file->slurp_utf8
                                                    : $tpl_file->slurp( binmode => ":unix:encoding(".$self->encoding.")")
        }

        $dom = XML::LibXML::jQuery->new($tpl_source);

        # check for data-plift-template attr, and use that element
        my $body = $dom->xfind('//body[@data-plift-template]');

        if ($body->size) {

            my $selector = $body->attr('data-plift-template');
            my $template_element = $dom->find($selector);
            confess "Can't find template via selector '$selector' (referenced at <body data-plift-template=\"$selector\">)."
                unless $template_element->size;

            # create new document for the template elment
            $dom = j()->document->append($template_element)->contents;
        }

        # cache it
        if ($self->enable_cache) {

            # control cache size
            if (scalar keys(%$cache) == $self->max_cached_files) {

                my @least_used = sort { $cache->{$b}{last_hit} <=> $cache->{$a}{last_hit} }
                                 keys %$cache;

                delete $cache->{$least_used[0]};
            }

            $cache->{$cache_key} = {
                dom   => $dom->document->clone,
                etag => $tpl_etag,
                hits => 0,
                last_hit => 0,
            };
        }
    }

    # adopt into document
    if (my $existing_document = $ctx->document) {

        $existing_document = $existing_document->get(0);

        # replace DTD
        if (my $dtd = $dom->{document}->internalSubset) {
            $existing_document->removeInternalSubset;
            $existing_document->createInternalSubset( $dtd->getName, $dtd->publicId, $dtd->systemId );
        }

        # adopt nodes
        my @nodes = map { $existing_document->adoptNode($_); $_ }
                    grep { $_->nodeType != XML_DTD_NODE }
                    # grep { $_->getOwner->nodeType == XML_DOCUMENT_NODE }
                    @{ $dom->{nodes} };

        # reinstantitate on new document
        $dom = $dom->_new_nodes(\@nodes, undef, $existing_document);
    }

    # 1st tempalte loaded, set contex document
    else {
        $ctx->document($dom->document);
    }

    $dom;
}

sub _find_template_file {
    my ($self, $template_name, $paths) = @_;

    # clean \x00 char that can be used to truncate our string
    $template_name =~ tr/\x00//d;

    foreach my $path (@$paths) {

        if (-e (my $file = "$path/$template_name.html")) {

            $file = Path::Tiny->new($file);
            $path = Path::Tiny->new($path);

            # if suspicious template name, check file is really child of path
            if ($template_name =~ /\.\.\//) {
                $file = $file->realpath;
                $path = $path->realpath;

                die "[Plift] attempt to traverse out of path via '$template_name'"
                    unless $path->subsumes($file)
            }

            return wantarray ? ($file, $path) : $file;
        }
    }

    return;
}

sub _load_snippet {
    my ($self, $ns, $name, $params) = @_;

    my $class_sufixx = _camelize($name);
    my @try_classes = map { join '::', $_, $class_sufixx } @$ns;
    my $snippet_class = Class::Load::load_first_existing_class @try_classes;


    $snippet_class->new($params);
}

# borrowed from Mojo::Util :)
sub _camelize {
    my $str = shift;
    return $str if $str =~ /^[A-Z]/;

    # CamelCase words
    return join '::', map {
        join( '', map { ucfirst lc } split '_' )
    } split '-', $str;
}


1;
__END__

=encoding utf-8

=head1 NAME

Plift - HTML Template Engine + Custom HTML Elements

=head1 SYNOPSIS

    use Plift;

    my $plift = Plift->new(
        path    => \@paths,                               # default ['.']
        plugins => [qw/ Script Blog Gallery GoogleMap /], # plugins not included
    );

    my $tpl = $plift->template("index");

    # set render directives
    $tpl->at({
        '#name' => 'fullname',
        '#contact' => [
            '.phone' => 'contact.phone',
            '.email' => 'contact.email'
        ]
    });

    # render render with data
    my $document = $tpl->render({

        fullname => 'Carlos Fernando Avila Gratz',
        contact => {
            phone => '+55 27 1234-5678',
            email => 'cafe@example.com'
        }
    });

    # print
    print $document->as_html;


=head1 DESCRIPTION

Plift is a HTML template engine which enforces strict separation of business logic
from the view. It is designer friendly, safe, extensible and fast enough to
be used as a web request renderer. This engine tries to follow the principles
described in the paper I<Enforcing Strict Model-View Separation in Template Engines>
by Terence Parr of University of San Francisco. The goal is to provide suficient
power without providing constructs that allow separation violations.

=head1 MANUAL

This document is the reference for the Plift class. The manual pages (not yet
complete) are:

=over

=item L<Plift::Manual::Tutorial>

Step-by-step intruduction to Plift. "Hello World" style.

=item L<Plift::Manual::DesignerFriendly>

Pure HTML5 template files makes everything easier to write and better to maintain.
Designers can use their WYSIWYG editor, backend developers can unit test their
element renderers.

=item L<Plift::Manual::Inception>

Talks about the web framework that inspired Plift, and its 'View-First'
approach to web request handling. (As opposed to the widespread 'Controller-First').

=item L<Plift::Manual::CustomHandler>

Explains how Plift is just an engine for reading/parsing HTML files, and
dispaching subroutine handlers bound to XPath expressions. You will learn how
to write your custom handlers using the same dispaching loop as the builtin
handlers.

=back

=head1 METHODS

=head2 add_handler

=over

=item Arguments: \%parameters

=back

Binds a handler to one or more html tags, attributes, or xpath expression.
Valid parameters are:

=over

=item tag

Scalar or arrayref of HTML tags bound to this handler.

=item attribute

Scalar or arrayref of HTML attributes bound to this handler.

=item xpath

XPath expression matching the nodes bound this handler.

=back

See L<Plift::Manual::CustomHandler>.

=head2 template

    $context = $plift->template($template_name, \%options)

Creates a new L<Plift::Context> instance, which will load, process and render
template C<$template_name>. See L<Plift::Context/at>, L<Plift::Context/set> and
L<Plift::Context/render>.

=head2 process

    $document = $plift->process($template_name, \%data, \@directives)

A shortcut method.
A new context is created via  L</template>, rendering directives are set via
L<Plift::Context/at> and finally the template is rendered via L<Plift::Context/render>.
Returns a L<XML::LibXML::jQuery> object representing the final processed document.

    my %data = (
        fullname => 'John Doe',
        contact => {
            phone => 123,
            email => 'foo@example'
        }
    );

    my @directives =
        '#name' => 'fullname',
        '#name@title' => 'fullname',
        '#contact' => {
            'contact' => [
                '.phone' => 'phone',
                '.email' => 'email',
            ]
    );

    my $document = $plift->process('index', \%data, \@directives);

    print $document->as_html;

=head2 render

    $html = $plift->render($template_name, \%data, \@directives)

A shortcut for C<< $plift->process()->as_html >>.

=head2 load_components

    $plift = $plift->load_components(@components)

Loads one or more Plift components. For each component, we build a class name
by prepending C<Plift::> to the component name, then load the class, instantiate
a new object and call C<< $component->register($self) >>.

See L<Plift::Manual::CustomHandler>.

=head1 SIMILAR PROJECTS

This is a list of modules (that I know of) that pursue similar goals:

=over

=item L<HTML::Template>

Probably one of the first to use (almost) valid html files as templates, and
encourage less business logic to be embedded in the templates.

=item L<Template::Pure>

Perl implementation of Pure.js. This module inspired Plift's render directives.

=item L<Template::Semantic>

Similar to Template::Pure, but the render directives points to the actual data
values, instead of datapoints. Which IMHO makes the work harder.

=item L<Template::Flute>

Uses a XML specification format for the rendering directives. Has lots of other
features.

=back

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
