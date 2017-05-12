use strict;
use warnings;
package Plack::App::DAIA;
#ABSTRACT: DAIA Server as Plack application
our $VERSION = '0.55'; #VERSION
use v5.10.1;

use parent 'Plack::Component';
use LWP::Simple qw(get);
use Encode;
use JSON;
use DAIA;
use Scalar::Util qw(blessed);
use Try::Tiny;
use Plack::Util::Accessor qw(xslt root warnings errors code idformat initialized safe);
use Plack::Middleware::Static;
use File::ShareDir qw(dist_dir);

use Carp;
use Plack::Request;

our %FORMATS  = DAIA->formats;

sub prepare_app {
    my $self = shift;
    return if $self->initialized;

    $self->init;
    $self->errors(0) unless defined $self->errors;
    $self->warnings(1) if $self->errors or not defined $self->warnings;
    $self->idformat( qr{^.*$} ) unless defined $self->idformat;
    $self->safe(1) unless defined $self->safe;
    $self->xslt('daia.xsl') if ($self->xslt // 1) eq 1;

    $self->{client} = Plack::Middleware::Static->new(
        path => qr{daia\.(xsl|css|xsd)$|xmlverbatim\.xsl$|icons/[a-z0-9_-]+\.png$},
        root => ($self->root || dist_dir('Plack-App-DAIA'))
    ) if $self->xslt;

    $self->initialized(1);
}

sub init {
    # initialization hook
}

sub call_client {
    my ($self, $req) = @_;

    if ( $self->{client} and $req->path ne '/' and !keys %{$req->parameters} ) {
        return $self->{client}->_handle_static( $req->env );
    } else {
        return;
    }
}

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    my $id     = $req->param('id') // '';
    my $format = lc($req->param('format') // '');

    # serve parts of the XSLT client
    my $res = $self->call_client($req);
    return $res if $res;

    # validate identifier
    my ($invalid_id, $error, %parts) = ('',undef);
    if ( $id ne '' and ref $self->idformat ) {
        if ( ref $self->idformat eq 'Regexp' ) {
            if ( $id =~ $self->idformat ) {
                %parts = %+; # named capturing groups
            } else {
                $invalid_id = $id;
                $id = "";
            }
        }
    }

    if ( $self->warnings ) {
        if ( $invalid_id ne '' ) {
            $error = 'unknown identifier format';
        } elsif ( $id eq ''  ) {
            $error = 'please provide a document identifier';
        }
    }

    # retrieve and construct response
    my ($status, $daia) = (200, undef);
    if ( $error and $self->errors ) {
        $daia = DAIA::Response->new;
    } else {
        if ($self->safe) {
            try {
                $daia = $self->retrieve( $id, %parts );
            } catch {
                chomp($error = "request method died: $_");
                $status = 500;
            }
        } else {
            $daia = $self->retrieve( $id, %parts );
        }
        if (!$daia or !blessed $daia or !$daia->isa('DAIA::Response')) {
            $daia = DAIA::Response->new;
            $error = 'request method did not return a DAIA response'
                unless $error;
            $status = 500;
        }
    }

    if ( $error and $self->warnings ) {
        $daia->addMessage( 'en' => $error, errno => 400 );
    }

    $self->as_psgi( $status, $daia, $format, $req->param('callback') );
}

sub retrieve {
    my $self = shift;
    return $self->code ? $self->code->(@_) : undef;
}

sub as_psgi {
    my ($self, $status, $daia, $format, $callback) = @_;
    my ($content, $type);

    $type = $FORMATS{$format} unless $format eq 'xml';
    $content = $daia->serialize($format) if $type;

    if (!$content) {
        $type = "application/xml; charset=utf-8";
        if ( $self->warnings ) {
            if ( not $format ) {
                $daia->addMessage( 'en' => 'please provide an explicit parameter format=xml', 300 );
            } elsif ( $format ne 'xml' ) {
                $daia->addMessage( 'en' => 'unknown or unsupported format', 300 );
            }
        }
        $content = $daia->xml( header => 1, xmlns => 1, ( $self->xslt ? (xslt => $self->xslt) : () )  );
    } elsif ( $type =~ qr{^application/javascript} and ($callback || '') =~ /^[\w\.\[\]]+$/ ) {
        $content = "$callback($content)";
    }

    return [ $status, [ "Content-Type" => $type ], [ encode('utf8',$content) ] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::DAIA - DAIA Server as Plack application

=head1 VERSION

version 0.55

=head1 SYNOPSIS

Either derive from Plack::App::DAIA

    package Your::App;
    use parent 'Plack::App::DAIA';

    sub init {
        my $self = shift;
        $self->idformat( qr{^[a-z]+:.*$} ) unless $self->idformat;
    }

    sub retrieve {
        my ($self, $id, %idparts) = @_;

        my $daia = DAIA::Response->new;

        # construct full response ...

        return $daia;
    };

    1;

or pass a code reference as option C<code>:

    use Plack::App::DAIA;

    Plack::App::DAIA->new(
        code => sub {
            my ($id, %idparts) = @_;

            my $daia = DAIA::Response->new;

            # construct full response ...

            return $daia;
        },
        idformat => qr{^[a-z]+:.*$}
    );

=head1 DESCRIPTION

This module implements a B<Document Availability Information API> (L<DAIA>)
server as PSGI application. A DAIA server receives two URL parameters:

=over 4

=item B<id>

refers to the document to retrieve availability information. The id is parsed
based on the L</idformat> option and passed to an internal L</retrieve> method,
which must return a L<DAIA::Response> object.

=item B<format>

specifies a DAIA serialization format, that the resulting L<DAIA::Response> is
returned in. By default the formats C<xml> (DAIA/XML, the default), C<json>
(DAIA/JSON), and C<rdfjson> (DAIA/RDF in RDF/JSON) are supported. Additional
RDF serializations (C<rdfxml>, C<turtle>, and C<ntriples>) are supported if
L<RDF::Trine> is installed. If L<RDF::NS> is installed, the RDF/Turtle output
uses well-known namespace prefixes. Visual RDF graphs are supported with format
C<svg> and C<dot> if L<RDF::Trine::Exporter::GraphViz> is installed and C<dot>
is in C<$ENV{PATH}>.

=back

This module automatically adds appropriate warnings and error messages. A
simple HTML interface based on client side XSLT is added with option C<xslt>.

=head1 METHODS

=head2 new ( [%options] )

Creates a new DAIA server. Supported options are

=over 4

=item code

Code reference to the C<retrieve> method if you prefer not to create a
module derived from this module.

=item xslt

Path of a DAIA XSLT client to attach to DAIA/XML responses. Set to C<daia.xsl>
by default.  The default client is provided in form of three files
(C<daia.xsl>, C<daia.css>, C<xmlverbatim.xsl>) and DAIA icons, all shipped
together with this module. Enabling HTML client also enables serving the DAIA
XML Schema as C<daia.xsd>.

Set C<< xslt => 0 >> to disable the client.

You may need to adjust the path if your server rewrites the request path.

=item root

Path of a directory with XSLT client files.

=item warnings

Enable warnings in the DAIA response (enabled by default).

=item errors

Enable warnings and directly return a response without calling the retrieve
method on error.

=item idformat

Optional regular expression to validate identifiers. Invalid identifiers are
set to the empty string before they are passed to the C<retrieve> method. In
addition an error message "unknown identifier format" is added to the response,
if the option C<warnings> are enabled. If the option C<errors> is enabled,
the C<retrieve> method is not called on error.

It is recommended to use regular expressions with named capturing groups
as introduced in Perl 5.10. The named parts are also passed to the
C<retrieve method>. For instance:

  idformat => qr{^ (?<prefix>[a-z]+) : (?<local>.+) $}x

will give you C<$parts{prefix}> and C<$parts{local}> in the retrieve method.

=item safe

Catch errors on the request format if enabled (by default). You may want to
disable this to get a stack trace if the request method throws an error.

=item initialized

Stores whether the application had been initialized.

=back

=head2 retrieve ( $id [, %parts ] )

Must return a status and a L<DAIA::Response> object. Override this method
if you derive an application from Plack::App::DAIA. By default it either
calls the retrieve code, as passed to the constructor, or returns undef,
so a HTTP 500 error is returned.

This method is passed the original query identifier and a hash of named
capturing groups from your identifier format.

=head2 init

This method is called by Plack::Component::prepare_app, once before the first
request and before undefined options are set to their default values. You can
define this method in you subclass as initialization hook, for instance to set
default option values. Initialization during runtime can be triggered by
setting C<initialized> to false.

=head2 as_psgi ( $status, $daia [, $format [, $callback ] ] )

Serializes a L<DAIA::Response> in some DAIA serialization format (C<xml> by
default) and returns a a PSGI response with given HTTP status code.

=head1 EXAMPLES

You can also mix this application with L<Plack> middleware.

It is highly recommended to test your services! Testing is made as easy as
possible with the L<provedaia> command line script.

This module contains a dummy application C<app.psgi> and a more detailed
example C<examples/daia-ubbielefeld.pl>.

=head1 SEE ALSO

Plack::App::DAIA is derived from L<Plack::Component>. Use L<Plack::DAIA::Test>
and L<provedaia> (using L<Plack::App::DAIA::Test::Suite>) for writing tests.
See L<Plack::App::DAIA::Validator> for a DAIA validator and converter.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
