use strict;
use warnings;

package Pod::Weaver::Plugin::Include;

our $VERSION = 'v0.1.5';

# ABSTRACT: Support for including sections of Pod from other files


use Moose;
use namespace::autoclean;
with qw<Pod::Weaver::Role::Dialect Pod::Weaver::Role::Preparer>;

has pod_path => (
    is      => 'rw',
    builder => 'init_pod_path',
);

has insert_errors => (
    is      => 'rw',
    builder => 'init_insert_errors',
);

has input => ( is => 'rw', );

around BUILDARGS => sub {
    my $orig   = shift;
    my $class  = shift;
    my ($args) = @_;

    if ( $args->{pod_path} && !ref( $args->{pod_path} ) ) {
        $args->{pod_path} = [ split /:/, $args->{pod_path} ];
    }

    return $orig->( $class, @_ );
};

sub prepare_input {
    my $this = shift;
    my ($input) = @_;

    $this->input($input);
}

sub translate_dialect {
    my $this = shift;
    my ($node) = @_;

    Pod::Weaver::Plugin::Include::Transformer->new( callerPlugin => $this, )
      ->transform_node($node);
}

sub init_pod_path {
    return [qw<lib>];
}

sub init_insert_errors {
    return 0;
}

package Pod::Weaver::Plugin::Include::Transformer {
    use Pod::Weaver::Plugin::Include::Finder;

    use Moose;
    use namespace::autoclean;
    with qw<Pod::Elemental::Transformer>;

    has callerPlugin => (
        is  => 'rw',
        isa => 'Pod::Weaver::Plugin::Include',
    );

    has logger => (
        is      => 'ro',
        lazy    => 1,
        builder => 'init_logger',
    );

    has finder => (
        is      => 'rw',
        lazy    => 1,
        isa     => 'Pod::Weaver::Plugin::Include::Finder',
        builder => 'init_finder',
    );

    has _children => (
        is      => 'rw',
        isa     => 'ArrayRef',
        lazy    => 1,
        clearer => '_clear_children',
        default => sub { [] },
    );

    has _skipContent => (
        is      => 'rw',
        isa     => 'Bool',
        default => 0,
    );

    sub _add_child {
        my $this = shift;

        $this->logger->log_debug( "Adding a child:",
            map { $_->as_pod_string } ( ref( $_[0] ) ? $_[0] : [ $_[0] ] ) );
        $this->logger->log_debug("Skipping the child") if $this->_skipContent;

        return if $this->_skipContent;

        if ( ref( $_[0] ) eq 'ARRAY' ) {
            push @{ $this->_children }, @{ $_[0] };
        }
        else {
            push @{ $this->_children }, $_[0];
        }
    }

    sub _error_case {
        my $this = shift;
        my $msg = join( "", @_ );

        $this->logger->log($msg);

        if ( $this->callerPlugin->insert_errors ) {
            $this->_add_child(
                Pod::Elemental::Element::Pod5::Ordinary->new(
                    content => "I<POD INCLUDE ERROR: " . $msg . ">",
                )
            );
        }
    }

    sub _resetSkipIf {
        my $this = shift;
        my $para = shift;

        $this->logger->log_debug( "_resetSkipIf for",
            ref($para), ( $para->can('command') ? $para->command : "" ) );

        if ( $this->_skipContent ) {
            $this->_skipContent(0)
              if $para->isa('Pod::Elemental::Element::Pod5::Command')
              && $para->command eq 'tmpl';
            $this->logger->log_debug( "PARA IS:", ref($para) );
            $this->logger->log_debug( "Skipping content",
                ( $this->_skipContent ? "on" : "off" ) );
        }
    }

    sub _process_children {
        my $this = shift;
        my ( $children, %params ) = @_;

        my $curSrc = $params{source} || "main";
        my $included =
          $params{'.included'} || {};    # Hash of already included sources.
        my $logger = $this->callerPlugin->logger;

        $logger->log_debug( "Processing source "
              . $curSrc
              . " with "
              . scalar(@$children)
              . " children" )
          if defined $curSrc;

        for ( my $i = 0 ; $i < @$children ; $i++ ) {
            my $para = $children->[$i];

            $this->_resetSkipIf($para);

            if ( $para->isa('Pod::Elemental::Element::Pod5::Command') ) {
                $logger->log_debug( ( $curSrc ? "[$curSrc] " : "" )
                    . "Current command: "
                      . $para->command );
                if ( $para->command eq 'srcAlias' ) {
                    my ( $alias, $source ) = split ' ', $para->content, 2;
                    unless ( $this->finder->register_alias( $alias, $source ) )
                    {
                        $this->logger->log( "No source '", $source,
                            "' found for alias '",
                            $alias, "'\n" );
                    }
                }
                elsif ( $para->command eq 'include' ) {
                    my ( $name, $source ) = split /\@/, $para->content, 2;
                    $logger->log_debug(
                        "[$curSrc] Including $name from $source");

                    unless ( $included->{$source}{$name} ) {
                        $included->{$source}{$name} = $curSrc;
                        my $template = $this->finder->get_template(
                            template => $name,
                            source   => $source,
                        );
                        if ( defined $template ) {
                            $this->_process_children(
                                $template,
                                source      => $source,
                                '.included' => $included,
                            );
                        }
                        else {
                            $this->_error_case( "Can't load template '",
                                $name, "' from '", $source, "'.", );
                        }
                    }
                    else {
                        $this->_error_case(
                            "Circular load: ",
                            $name,
                            "@",
                            $source,
                            " has been loaded previously in ",
                            $included->{$source}{$name},
                        );
                    }
                }
                elsif ( $para->command eq 'tmpl' ) {
                    my $attrs = $this->finder->parse_tmpl( $para->content );

                    if ( $attrs->{badName} ) {
                        $this->logger->log(
                            "Bad tmpl definition '",
                            $para->content,
                            "': no valid name found"
                        );
                    }
                    else {
                        $this->_skipContent( $attrs->{hidden} );
                    }
                }
                else {
                    # Any other kind of child
                    $this->_add_child($para);
                }
            }
            else {
                $this->_add_child($para);
            }
        }
    }

    sub transform_node {
        my ( $this, $node ) = @_;

        $this->_clear_children;

        $this->_process_children( $node->children );

        $node->children( $this->_children );

        return $node;
    }

    sub init_finder {
        my $this = shift;

        return Pod::Weaver::Plugin::Include::Finder->new(
            callerPlugin => $this->callerPlugin, );
    }

    sub init_logger {
        my $this = shift;
        return $this->callerPlugin->logger;
    }

    __PACKAGE__->meta->make_immutable;
    no Moose;

}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Include - Support for including sections of Pod from other files

=head1 VERSION

version v0.1.5

=head1 SYNOPSIS

    # weaver.ini
    [-Include]
    pod_path = lib:bin:docs/pod
    insert_errors = 0

=head1 DESCRIPTION

This is a L<Pod::Weaver> plugin for making it possible to include segments of
Pod documentation being included from one file into another. This is useful when
one has a piece of documentation which is nice to have included into a couple of
documentations. So, instead of telling a user to 'go see this info in I<that>
file' one could simply have this info included from I<that> file into I<this>
file.

For example, let's say we have a script C<useful_tool> which is handling its
command line processing to a module C<Core>. In turn, the module gathers
information about standard command line options from modules C<Core::Mod1>,
C<Core::Mod2>, etc. So far, so good until one writes another script
C<noless_useful>, which is based upon the module C<Core> too. Yet, even worse –
it adds its own command lines the list gathered by C<Core>! With standard Pod
documentation for the common set of options would have to be copy-pasted into
each script documentation. For the latter one it's own options must be included.
And then if any documentation would be changed in the original modules we would
have not forget update both scripts' docs too!

Phew...

C<Pod::Weaver::Plugin::Include> solves the issue by defining a concept of
template (borrowed from archaic L<Pod::Template>) and allowing a template to be
included by a third-party pod:

    # File lib/Core/Mod1.pm
    package Core::Mod1;
     
    ...
    
    # Template options won't be included into resulting Pod.
    =pod
    
    Here we define command line options for later use by calling module.
     
    =tmpl -options
    
    =item B<--option1>
    
    document it
    
    =item B<--option2>
    
    repeat
    
    =tmpl
    
    =cut
    
    1;
    __END__
    
    
    
    # File lib/Core/Mod2.pm
    package Core::Mod2
    
    =head1 Options
    
    Here is the options we declare in this module:
    
    =over 4
    
    =tmpl options
    
    =item B<--file=>I<source_file>
    
    Whatever it means.
    
    =item B<--ignore-something>
    
    ... we'll document it. Some day...
    
    =tmpl
    
    =back
    
    You will find these in your script documentation too.
    
    =cut
    
    1;
    __END__
    
    
    
    # File lib/Core.pm
    package Core;
    
    =pod
    
    =srcAlias mod2opts Core/Mod2.pm
    
    =tmpl coreOpts
    
    =over 4
    
    =item B<--help>
    
    Display this help
    
    =include options@Core::Mod1
    
    =include options@mod2opts
    
    =tmpl
    
    =cut
    
    1;
    __END__

Now, after processing this code by C<Include> plugin, resulting F<lib/Core.pm>
documentation will contain options from both C<Core::Mod1> and C<Core::Mod2>.
Yet, the C<noless_useful> script would has the following section in its
documentation:

    # File: noless_useful
    
    =head1 OPTIONS
    
    =over 4
    
    include coreOpts@Core
    
    =item B<--script-opt>
    
    This is added by the script code
    
    =back
    
    =cut

and this section will have all the options defined by the modules plus what
is been added by the script itself.

=head2 Syntax

Three Pod commands are added by this plugin:

    =tmpl [[-]tmplName]
    =srcAlias alias source
    =include tmplName@source

=over 4

=item B<=tmpl>

Declares a template if I<tmplName> is defined. Prefixing the name with a dash
tells the plugin that template body is 'hidden' and must not be included into
enclosing documentation and will only be visible as a result of C<=include>
command.

Template's name must start with either a alpha char or underscore (C<_>) and
continued with alpha-numeric or underscore.

A template body is terminated by another C<=tmpl> command. If C<=tmpl> doesn't
have the name parameter then it acts as a terminating command only. For example:

    =head1 SECTION
    
    Section docs...
    
    =tmpl tmpl1
    
    Template 1
    
    =tmpl -tmpl2
    
    Template 2
    
    =tmpl
    
    Some more docs
    
    =tmpl -tmpl3
    
    Template 3
    
    =tmpl
    
    =cut

The above code declares three templates of which I<tmpl2> and I<tmpl3> are
hidden and I<tmpl1> is included into the resulting Pod. The I<"Some more docs">
paragraph is not a part of any template.

=item B<=srcAlias> 

Defines an alias for a source. The source could be either a file name or a
module name.

    =srcAlias mod1 Some::Very::Long::Module::Name1
    =srcAlias aPodFile pod/templates/some.pod

=item B<=include>

This command tries to locate a template defined by name I<tmplName> in a source
defined by either a file name, a module name, or by an alias and include it into
the output.

Missing template is an "Error Case" (see below).

=back

=head2 Error Cases

Plugin does its best as to not abort the building process. Errors are ignored
and only error messages are logged. But some error reports could be included
into generated pod if C<insert_errors> option is set to I<true> in
F<weaver.ini>. In this case the error message is also inserted into the
resulting Pod with I<Pod INCLUDE ERROR:> prefix.

=head2 Configuration variables

=over 4

=item B<pod_path>

Semicolon-separated list of directories to search for template sources.

Default: I<lib>

=item B<insert_errors>

Insert some error message into the resulting Pod.

=back

=head1 AUTHOR

Vadim Belman <vrurg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Vadim Belman.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
