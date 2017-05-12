package Mojolicious::Plugin::PetalTinyRenderer;
$Mojolicious::Plugin::PetalTinyRenderer::VERSION = '0.05';
use Mojo::Base 'Mojolicious::Plugin';
use Try::Tiny;

my $tal_ns = q{xmlns:tal="http://purl.org/petal/1.0/"};

__PACKAGE__->attr('config');

sub register {
    my ($self, $app, $conf) = @_;
    $self->config($conf);

    $app->renderer->add_handler($conf->{name} || 'tal' => sub { $self->_petal(@_) } );
}

sub _petal {
    my ($self, $renderer, $c, $output, $options) = @_;

    my $inline = $options->{inline};
    my $name   = defined $inline ? "inline" : $renderer->template_name($options);
    return undef unless defined $name;

    $$output = '';

    my $log = $c->app->log;

    if (defined $inline) {
        $log->debug(qq{Rendering inline template "$name".});
        $$output = $self->_render_xml($inline, $c, $name);
    }
    else {
        if (defined(my $path = $renderer->template_path($options))) {
            $log->debug(qq{Rendering template "$name".});

            my $encoding = $self->config->{encoding} // ":encoding(UTF-8)";

            if (open my $file, "<$encoding", $path) {
                my $xml = join "", <$file>;
                $$output = $self->_render_xml($xml, $c, $name);
                close $file;
            }
            else {
                $log->debug(qq{Template "$name" ($path) not readable.});
                return undef;
            }
        }
        elsif (my $d = $renderer->get_data_template($options)) {
            $log->debug(qq{Rendering template "$name" from DATA section.});
            $$output = $self->_render_xml($d, $c, $name);
        }
        else {
            $log->debug(qq{Template "$name" not found.});
            return undef;
        }
    }

    return 1;
}

sub _render_xml {
    my ($self, $xml, $c, $name) = @_;

    my $deldiv = 0;
    if ($xml !~ /\bxmlns:/) {
        $xml = "<div $tal_ns>$xml</div>";
        $deldiv = 1;
    }

    my $template = Petal::Tiny::_Mojo->new($xml);

    my $helper = Mojolicious::Plugin::PetalTinyRenderer::Helper->new(ctx => $c);

    my $html;
    try {
        $html = $template->process(%{$c->stash}, c => $c, h => $helper);
    }
    catch {
        my $validator;
        eval "use XML::Validate; \$validator = XML::Validate->new(Type => 'LibXML');";
        if ($validator) {
            $xml =~ s/<!DOCTYPE.*?>//;
            if ($validator->validate($xml)) {
                die "Petal::Tiny blew up handling '$name', and XML::Validate reports the XML is fine.\n\n$_";
            }
            else {
                my $e       = $validator->last_error;
                my $message = $e->{message} // "";
                die "Petal::Tiny blew up handling '$name', and XML::Validate reports:\n\n$message";
            }
        }
        else {
            die "Petal::Tiny blew up handling '$name'. Install XML::Validate and XML::LibXML for better diagnostics.\n\n$_";
        }
    };

    if ($deldiv) {
        $html =~ s,\A<div>,,;
        $html =~ s,</div>\z,,;
    }

    return $html;
}

1;

package
  Petal::Tiny::_Mojo;

use Mojo::Base 'Petal::Tiny';
use Scalar::Util 'blessed';

sub reftype {
    my ($self, $obj) = @_;
    return 'ARRAY' if blessed $obj and $obj->isa('Mojo::Collection');
    return $self->SUPER::reftype($obj);
}

1;

package
  Mojolicious::Plugin::PetalTinyRenderer::Helper;

use Mojo::Base -base;

our $AUTOLOAD;

__PACKAGE__->attr('ctx');

# stolen from  Mojolicious::Plugin::TtRenderer::Helper
sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;

    return if $method =~ /^[A-Z]+?$/;
    return if $method =~ /^_/;
    return if $method =~ /(?:\:*?)DESTROY$/;

    $method = (split '::' => $method)[-1];

    die qq/Unknown helper: $method/ unless $self->ctx->app->renderer->helpers->{$method};

    return $self->ctx->$method(@_);
}

# lifted from http://www.perlmonks.org/?node_id=44911
sub can {
    my ($self, $method) = @_;
    my $subref = $self->SUPER::can($method);
    return $subref if $subref; # can found it; it's a real method

    # Method doesn't currently exist; should it, though?
    return unless exists $self->ctx->app->renderer->helpers->{$method};

    # Return an anon sub that will work when it's eventually called
    sub {
        my $self = $_[0];

        # The method is being called.  The real method may have been
        # created in the meantime; if so, don't call AUTOLOAD again
        my $subref = $self->SUPER::can($method);
        goto &$subref if $subref;

        $AUTOLOAD=$method;
        goto &AUTOLOAD;
    };
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::PetalTinyRenderer - Petal::Tiny renderer plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('PetalTinyRenderer');

  # Mojolicious::Lite
  plugin 'PetalTinyRenderer';

=head1 DESCRIPTION

L<Mojolicious::Plugin::PetalTinyRenderer> is a renderer for templates
written for L<Petal::Tiny>, which is a Perl implementation of the
Template Attribute Language (TAL).

=head1 OPTIONS

L<Mojolicious::Plugin::PetalTinyRenderer> supports the following
option.

=head2 name

  # Mojolicious::Lite
  plugin PetalTinyRenderer => {name => 'petal'};

Handler name, defaults to C<tal>.

=head2 encoding

Encoding of the template-files as supplied to C<open>, defaults to C<:encoding(UTF-8)>.

=head1 STASH

The stash is directly available in the templates, see the use of foo in the example.

=head2 h

Helpers are available via the C<h> entry in the stash.

 <a tal:attributes="href h/url_for --index" href="/">go back to index</a>

=head2 c

The current controller instance can be accessed as C<c>.

 I see you are requesting a document from 
 <span tal:replace="c/req/headers/host">Lorem ipsum</span>.

=head1 USEFUL PATTERNS

Call helper-function without generating html (-- prefixes a literal
string):

 <span tal:condition="true:h/layout --default" tal:omit-tag="" />

Use a temporary variable to hold dynamically generated string for
helper function:

 <span tal:define="mytitle h/localization --login"
       tal:condition="true:h/title mytitle"
       tal:omit-tag="" />

Insert styled paragraph with error-message, if any (the structure
keyword means don't escape returned html):

 <p style="color:red" tal:condition="true:message" tal:content="structure message">
   Error message
 </p>

Include other action/template:

 <span tal:replace="structure h/include --example/welcome" />

You can loop over Mojo::Collections:

 <li tal:repeat="key some_mojo_collection" tal:content="key" />

See L<Petal::Tiny> for more.

Author's observation: If you need to write very complex
TAL-constructs, maybe you should reconsider what belongs in the
controller and what belongs in the template. TAL seems to be very good
at exposing this anti-pattern.

=head1 EXAMPLE

 use Mojolicious::Lite;

 plugin 'PetalTinyRenderer';

 get '/' => sub {
     my $self = shift;
     $self->stash( foo => Mojo::Collection->new(1,2,3) );
     $self->render('index');
 };

 app->start;

 __DATA__

 @@ layouts/default.html.tal
 <!DOCTYPE html>
 <html>
   <head><title tal:content="title">Lorem</title></head>
   <body tal:content="structure h/content">Ipsum</body>
 </html>

 @@ index.html.tal
 <span tal:condition="true:h/layout --default" tal:omit-tag="" />
 <span tal:condition="true:h/title --Welcome" tal:omit-tag="" />

 <p tal:repeat="i foo"><span tal:replace="i"/>: Welcome to the PetalTinyRenderer plugin!</p>

=head1 SEE ALSO

L<Petal::Tiny>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Lars Balker <lars@balker.dk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by DK Hostmaster A/S.

This is free software, licensed under:

  The MIT (X11) License

The MIT License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall
be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
