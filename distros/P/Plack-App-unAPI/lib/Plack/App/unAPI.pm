use strict;
package Plack::App::unAPI;
#ABSTRACT: Serve via unAPI
our $VERSION = '0.61'; #VERSION

use v5.10.1;

use parent 'Plack::Component';
use Plack::Util::Accessor qw(formats);

use Plack::Request;
use Carp;

sub prepare_app {
    my ($self) = @_;
    $self->_trigger_formats( $self->formats );
}

sub call {
    my ($self, $env) = @_;

    my $req    = Plack::Request->new($env);
    my $format = $req->param('format') // '';
    my $id     = $req->param('id') // '';
    
    # TODO: here we could first lookup the resource at the server
    # and sent 404 if no known format was specified
    # return 404 unless $self->available_formats($id);
    
    return $self->formats_as_psgi($id)
        if $format eq '' or $format eq '_';

    my $route = $self->formats->{$format};
    if ( !$route || !$route->{app} ) {
        my $res = $self->formats_as_psgi($id);
        $res->[0] = 406; # Not Acceptable
        return $res;
    }

    return $self->formats_as_psgi('')
        if $id eq '' and !($route->{always} // $self->formats->{_}->{always});

    my $res = eval { $route->{app}->($env) };
    my $error = $@;

    if ($error) {
        $error = "Internal crash with format=$format and id=$id: $error";
    } elsif (!_is_psgi_response($res)) {
        # we may also check response type...
        $error = "No PSGI response for format=$format and id=$id";
    }

    if ($error) { # TODO: catch only on request
        return [ 500, [ 'Content-Type' => 'text/plain' ], [ $error ] ];
    }

    $res;
}

# can return a subset of formats for some identifiers in a subclass
sub available_formats {
    my ($self, $id) = @_;
    return keys %{$self->formats};
}

sub formats_as_psgi {
    my ($self, $id) = @_;

    my $formats = $self->formats;

    my $status = 300; # Multiple Choices
    my $type   = 'application/xml; charset: utf-8';
    my @xml    = '<?xml version="1.0" encoding="UTF-8"?>';

    push @xml, _xmltag('<formats', id => ($id eq '' ? undef : $id ) ).">";

    foreach my $name (sort $self->available_formats($id)) {
        next if $name eq '_';
        push @xml, _xmltag('<format',
                name => $name,
                type => $formats->{$name}->{type},
                docs => $formats->{$name}->{docs})." />";
    }

    push @xml, '</formats>';

    return [ $status, [ 'Content-Type' => $type ], [ join "\n", @xml] ];
}

# TODO: better force lookup functions to return full/partial PSGI???
sub _lookup2psgi {
    my ($method, $type) = @_;
    # TODO: error response in corresponding content type and more headers
    sub {
        my ($env) = @_;
        my $id      = Plack::Request->new($env)->param('id') // '';
        my $content = $method->( $id, $env );
        return defined $content
            ? [ 200, [ 'Content-Type' => $type ], [ $content ] ]
            : [ 404, [ 'Content-Type' => 'text/plain' ], [ 'not found' ] ];
    };
}

# convert [  $app => $type, %about ] to { type => $type, %about }
# convert         [  $type, %about ] to { type => $type, %about }
sub _trigger_formats { # TODO: make Plack::App::unAPI::Format
    my ($self, $formats) = @_;

    $self->{formats} = { };

    foreach my $name (grep { $_ ne '_' } keys %$formats) {
        my $spec = $formats->{$name};
        if (ref $spec eq 'ARRAY') {
            
            my ($app, $type, %about) = @$spec % 2 ? (undef,@$spec) : @$spec;
            croak "unAPI format required MIME type" unless $type;

            if (!$app) {
                my $lookup = do {
                    my $method = "format_$name";
                    if (!$self->can($method)) {
                        croak __PACKAGE__." must implement method $method"; 
                    }
                    sub { $self->$method(@_); };
                };

                $app = _lookup2psgi( $lookup, $type );
            }

            $self->{formats}->{$name} = { type => $type, %about, app => $app };
        } # TODO: keep { ... }
    }

    $self->{formats}->{_} = $formats->{_};
}


###### FUNCTIONS

use parent 'Exporter';
our @EXPORT = qw(unAPI wrAPI);

## no critic
sub unAPI(@) { 
    Plack::App::unAPI->new( formats => { @_ } )->to_app;
}
## use critic

sub wrAPI {
    my ($code, $type, %about) = @_;

    my $app = _lookup2psgi( $code, $type );

    return [ $app => $type, %about ];
}

###### Utility

# checks whether PSGI conforms to PSGI specification
sub _is_psgi_response {
    my $res = shift;
    return (ref($res) and ref($res) eq 'ARRAY' and
        (@$res == 3 or @$res == 2) and
        $res->[0] =~ /^\d+$/ and $res->[0] >= 100 and
        ref $res->[1] and ref $res->[1] eq 'ARRAY');
}

sub _xmltag {
    my $name = shift;
    my %attr = @_;

    return $name . join '', map {
        my $val = $attr{$_};
        $val =~ s/\&/\&amp\;/g;
        $val =~ s/\</\&lt\;/g;
        $val =~ s/"/\&quot\;/g;
        " $_=\"$val\"";    
    } grep { defined $attr{$_} }
      grep { state $n=0; ++$n % 2; } @_;
}

1;

__END__

=pod

=head1 NAME

Plack::App::unAPI - Serve via unAPI

=head1 VERSION

version 0.61

=head1 SYNOPSIS

Create C<app.psgi> like this:

    use Plack::App::unAPI;

    my $get_json = sub { my $id = shift; ...; return $json; };
    my $get_xml  = sub { my $id = shift; ...; return $xml; };
    my $get_txt  = sub { my $id = shift; ...; return $txt; };

    unAPI
        json => wrAPI( $get_json => 'application/json' ),
        xml  => wrAPI( $get_xml  => 'application/xml' ),
        txt  => wrAPI( $get_txt  => 'text/plain', docs => 'http://example.com' );

The function C<wrAPI> facilitates definition of PSGI apps that serve resources
in one format, based on HTTP query parameter C<id>. One can also use custom
PSGI apps:

    use Plack::App::unAPI;

    my $app1 = sub { ... };   # PSGI app that serves resource in JSON
    my $app2 = sub { ... };   # PSGI app that serves resource in XML
    my $app3 = sub { ... };   # PSGI app that serves resource in plain text

    unAPI
        json => [ $app1 => 'application/json' ],
        xml  => [ $app2 => 'application/xml' ],
        txt  => [ $app3 => 'text/plain', docs => 'http://example.com' ];

One can also implement the unAPI Server as subclass of Plack::App::unAPI:

    package MyUnAPIServer;
    use parent 'Plack::App::unAPI';

    our $formats = {
            json => [ 'application/json' ],
            xml  => [ 'application/xml' ],
            txt  => [ 'text/plain', docs => 'http://example.com' ]
        };
    
    sub format_json { my $id = $_[1]; ...; return $json; }
    sub format_xml  { my $id = $_[1]; ...; return $xml; }
    sub format_txt  { my $id = $_[1]; ...; return $txt; }

=head1 DESCRIPTION

Plack::App::unAPI implements an L<unAPI|http://unapi.info> server as L<PSGI>
application. The HTTP request is routed to different PSGI applications based on
the requested format. An unAPI server receives two query parameters via HTTP
GET:

=over 4

=item id

a resource identifier to select the resource to be returned.

=item format

a format identifier. If no (or no supported) format is specified, a list of
supported formats is returned as XML document.

=back

=head1 METHODS

=head2 unAPI ( %formats )

Exported by default as handy alias for

    Plack::App::unAPI->new( formats => \%formats )->to_app

=head2 wrAPI ( $code, $type, [ %about ] )

This method returns an array reference to be passed to the constructor. The
first argument must be a simple code reference that gets called with C<id> as
only parameter. If its return value is C<undef>, a 404 response is returned.
Otherwise the code reference must return a serialized byte string (NO unicode
characters) that has MIME type C<$type>. To give an example:

    sub get_json { my $id = shift; ...; return $json; }

    # short form:
    my $app = wrAPI( \&get_json => 'application/json' );

    # equivalent code:
    my $app = [
        sub {
            my $id   = Plack::Request->new(shift)->param('id') // '';
            my $json = get_json( $id );
            return defined $json
                ? [ 200, [ 'Content-Type' => $type ], [ $json ] ]
                : [ 404, [ 'Content-Type' => 'text/plain' ], [ 'not found' ] ];
        } => 'application/json' 
    ];

=head1 CONFIGURATION

=over

=item formats

Hash reference that maps format names to PSGI applications. Each application is
wrapped in an array reference, followed by its MIME type and optional
information fields about the format. So the general form is:

    $format => [ $app => $type, %about ]

If a class implements method 'C<format_$format>' this form is also possible:

    $format => [ $type, %about ]

The following optional information fields are supported:

=over

=item docs

An URL of a document that describes the format

=item always

By default, the format list with HTTP status code 300 is returned if unless
both, format and id have been supplied. If 'always' is set to true, an empty
identifier will also be routed to the format's application.

=item quality

A number between 0.000 and 1.000 that describes the "source quality" for
content negotiation. The default value is 1.

=item encoding

One or more content encodings, for content negotiation. Typical values are
C<gzip> or C<compress>.

=item charset

The charset for content negotiation (C<undef> by default).

=item language

One or more languages for content negotiation (C<undef> by default).

=back

General options for all formats can be passed with the C<_> field (no format
can have the name C<_>).

By default, the result is checked to be valid PSGI (at least to some degree)
and errors in single applications are catched - in this case a response with
HTTP status code 500 is returned.

=back

=head2 FUNCTIONS

=head1 SEE ALSO

=over

=item

L<http://unapi.info>

=item

Chudnov et al. (2006): I<Introducing unAP>. In: Ariadne, 48,
<http://www.ariadne.ac.uk/issue48/chudnov-et-al/>.

=back

=encoding utf8

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
