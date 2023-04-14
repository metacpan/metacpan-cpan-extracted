# -*- Perl -*-
#
# a Gemini protocol client
#
#   "The conjunction of Jupiter with one of the stars of Gemini, which
#   'we ourselves have seen' (1.6.343b30) has been dated in recent years
#   to December 337 BC."
#    -- Malcolm Wilson. Structure and Method in Aristotle's Meteorologica

# NOTE this silently accepts URI with userinfo; those probably
# should be failed?
#
# KLUGE this may break if the URI module ever gets URI/gemini.pm
package URI::gemini {
    use URI;
    use parent 'URI::_server';
    sub default_port { 1965 }
    sub userinfo     { return undef }    # gemini has no userinfo
    sub secure       { 1 }

    sub canonical {
        my $self  = shift;
        my $other = $self->SUPER::canonical;
        $self->SUPER::userinfo(undef);    # gemini has no userinfo

        my $slash_path =
             defined( $other->authority )
          && !length( $other->path )
          && !defined( $other->query );

        if ($slash_path) {
            $other = $other->clone if $other == $self;
            $other->path("/");
        }
        $other;
    }
}

package Net::Gemini;
our $VERSION = '0.05';
use strict;
use warnings;
use Encode ();
use IO::Socket::SSL;
use Net::SSLeay;

sub _DEFAULT_BUFSIZE () { 4096 }

sub code    { $_[0]{_code} }      # 0..6 response code
sub content { $_[0]{_buf} }
sub error   { $_[0]{_error} }     # error message for 0 code
sub host    { $_[0]{_host} }
sub meta    { $_[0]{_meta} }
sub port    { $_[0]{_port} }
sub socket  { $_[0]{_socket} }
sub status  { $_[0]{_status} }    # two digit '1x', '2x', ... response code
sub uri     { $_[0]{_uri} }

# see VERIFICATION below; the caller should supply a custom callback.
# the default is thus "Trust On Almost Any Use" (TOAAU) or similar to
# what gg(1) of gmid does
sub _verify_ssl { 1 }

# minimal method to get a resource (see also ->request)
sub get {
    my ( $class, $source, %param ) = @_;
    my %obj;
    unless ( defined $source ) {
        @obj{qw(_code _error)} = ( 0, "source is not defined" );
        goto BLESSING;
    }

    $obj{_uri} = URI->new($source);
    unless ( $obj{_uri}->scheme eq 'gemini' ) {
        @obj{qw(_code _error)} = ( 0, "could not parse '$source'" );
        goto BLESSING;
    }
    @obj{qw/_host _port/} = ( $obj{_uri}->host, $obj{_uri}->port );

    my $yuri = $obj{_uri}->canonical;
    if ( length $yuri > 1024 ) {
        @obj{qw(_code _error)} = ( 0, "URI is too long" );
        goto BLESSING;
    }

    # VERIFICATION is based on the following link though much remains up
    # to the caller to manage
    # gemini://makeworld.space/gemlog/2020-07-03-tofu-rec.gmi
    eval {
        $obj{_socket} = IO::Socket::SSL->new(
            SSL_hostname        => $obj{_host},    # SNI
            SSL_verify_callback => sub {
                my ( $ok, $ctx_store, $certname, $error, $cert, $depth ) = @_;
                if ( $depth != 0 ) {
                    return 1 if $param{tofu};
                    return $ok;
                }
                ( $param{verify_ssl} || \&_verify_ssl )->(
                    @obj{qw(_host _port)},
                    Net::SSLeay::X509_get_fingerprint( $cert, 'sha256' ),
                    Net::SSLeay::P_ASN1_TIME_get_isotime( Net::SSLeay::X509_get_notAfter($cert) ),
                    $ok,
                    $cert
                );
            },
            ( exists $param{ssl} ? %{ $param{ssl} } : () ),
            PeerHost => $obj{_host},
            PeerPort => $obj{_port},
        ) or die $!;
        1;
    } or do {
        @obj{qw(_code _error)} = ( 0, "IO::Socket::SSL failed: $@" );
        goto BLESSING;
    };

    binmode $obj{_socket}, ':raw';

    my $n = syswrite $obj{_socket}, "$yuri\r\n";
    unless ( defined $n ) {
        @obj{qw(_code _error)} = ( 0, "send URI failed: $!" );
        goto BLESSING;
    }
    # KLUGE we're done with the connection as a writer at this point,
    # but IO::Socket::SSL does not appear to offer a public means to
    # only call shutdown and nothing else. using this is a bit risky
    # should the IO::Socket::SSL internals change
    Net::SSLeay::shutdown( ${ *{ $obj{_socket} } }{'_SSL_object'} )
      if $param{early_shutdown};

    # get the STATUS SPACE header response (and, probably, more)
    $obj{_buf} = '';
    while (1) {
        my $n = sysread $obj{_socket}, my $buf, $param{bufsize} || _DEFAULT_BUFSIZE;
        unless ( defined $n ) {
            @obj{qw(_code _error)} = ( 0, "recv response failed: $!" );
            goto BLESSING;
        }
        if ( $n == 0 ) {
            @obj{qw(_code _error)} = ( 0, "recv EOF" );
            goto BLESSING;
        }
        $obj{_buf} .= $buf;
        last if length $obj{_buf} >= 3;
    }
    if ( $obj{_buf} =~ m/^(([1-6])[0-9])[ ]/ ) {
        @obj{qw(_status _code)} = ( $1, $2 );
        substr $obj{_buf}, 0, 3, '';
    } else {
        @obj{qw(_code _error)} =
          ( 0, "invalid response " . sprintf "%vx", substr $obj{_buf}, 0, 3 );
        goto BLESSING;
    }

    # META -- at most 1024 characters, followed by \r\n. the loop is in
    # the event the server is being naughty and trickling bytes in one
    # by one (probably you will want a timeout somewhere, or an async
    # version of this code)
    my $bufsize = $param{bufsize} || _DEFAULT_BUFSIZE;
    while (1) {
        if ( $obj{_buf} =~ m/^(.{0,1024}?)\r\n/ ) {
            $obj{_meta} = $1;
            my $len = length $obj{_meta};
            if ( $len == 0 ) {
                # special case mentioned in the specification
                $obj{_meta} = 'text/gemini; charset=utf-8';
            } else {
                eval {
                    $obj{_meta} = Encode::decode( 'UTF-8', $obj{_meta}, Encode::FB_CROAK );
                    1;
                } or do {
                    @obj{qw(_code _error)} = ( 0, "failed to decode meta: $@" );
                    goto BLESSING;
                };
                substr $obj{_buf}, 0, $len + 2, '';    # +2 for the \r\n
            }
            last;
        } else {
            my $len = length $obj{_buf};
            if ( $len > 1024 ) {
                @obj{qw(_code _error)} = ( 0, "meta is too long" );
                goto BLESSING;
            }
            my $buf;
            my $n = sysread $obj{_socket}, $buf, $bufsize;
            unless ( defined $n ) {
                @obj{qw(_code _error)} = ( 0, "recv response failed: $!" );
                goto BLESSING;
            }
            if ( $n == 0 ) {
                @obj{qw(_code _error)} = ( 0, "recv EOF" );
                goto BLESSING;
            }
            $obj{_buf} .= $buf;
        }
    }

  BLESSING:
    close $obj{_socket} if defined $obj{_socket} and $obj{_code} != 2;
    bless( \%obj, $class ), $obj{_code};
}

# drain what remains (if anything) via a callback interface. assumes
# that a ->get call has been made
sub getmore {
    my ( $self, $callback, %param ) = @_;

    my $len = length $self->{_buf};
    if ($len) {
        $callback->( $self->{_buf}, $len ) or return;
    }

    my $bufsize = $param{bufsize} || 4096;
    while (1) {
        my $buf;
        $len = sysread $self->{_socket}, $buf, $bufsize;
        if ( !defined $len ) {
            die "sysread failed: $!\n";
        } elsif ( $len == 0 ) {
            last;
        }
        $callback->( $buf, $len ) or return;
    }
    close $self->{_socket};
}

1;
__END__

=head1 NAME

Net::Gemini - a small gemini client

=head1 SYNOPSIS

  use Net::Gemini;
  my ($gem, $code) = Net::Gemini->get('gemini://example.org/');

  use Syntax::Keyword::Match;
  match($code : ==) {
    case(0) { die "request failed " . $gem->error }
    case(1) { ... $gem->meta as prompt for input ... }
    case(2) { ... $gem->meta and $gem->content and ... }
    case(3) { ... $gem->meta as redirect ... }
    case(4) { ... $gem->meta as temporary failure ... }
    case(5) { ... $gem->meta as permanent failure ... }
    case(6) { ... $gem->meta as client certificate message ... }
  }


=head1 DESCRIPTION

This module implements code that may help implement a gemini
client in Perl.

=head2 CAVEATS

It's a pretty beta module.

The default SSL verification is more or less to accept the connection;
this is perhaps not ideal. The caller will need to implement TOFU or a
similar means of verifying the other end.

L<gemini://makeworld.space/gemlog/2020-07-03-tofu-rec.gmi>

=head1 METHODS

=over 4

=item B<get> I<URI> [ parameters ... ]

Tries to obtain the given gemini I<URI>.

Returns an object and a result code. The socket is set to use the
C<:raw> B<binmode>. The result code will be C<0> if there was a problem
with the request--that the URI failed to parse, or the connection
failed--or otherwise a gemini code in the range of C<1> to C<6>
inclusive, which will indicate the next steps any subsequent code
should take.

For code C<2> responses the response body may be split between
B<content> and whatever remains unread in the socket, if anything.

Parameters include:

=over 4

=item B<bufsize> => I<strictly-positive-integer>

Size of buffer to use for requests, 4096 by default. Note that a naughty
server may return data in far smaller increments than this.

=item B<early_shutdown> => I<boolean>

If true, attempts an early shutdown of the SSL connection after the
request is sent. This fiddles with the internal state of
L<IO::Socket::SSL> as the C<shutdown> call does not appear to be exposed
outside the module.

Use with caution.

=item B<ssl> => { params }

Passes the given parameters to the L<IO::Socket::SSL> constructor. These
could be used to configure e.g. the C<SSL_verify_mode> or to set a
verification callback, or to specify a custom SNI host via
C<SSL_hostname>.

=item B<tofu> => I<boolean>

If true, only the leaf certificate will be checked. Otherwise, the full
certificate chain will be verified by default, which is probably not
what you want when trusting the very first leaf certificate seen.

=item B<verify_ssl> => code-reference

Custom callback function to handle SSL verification. The default is to
accept the connection (Trust On All Uses), which is perhaps not ideal.
The callback function is passed the host, port, certificate digest, and
certificate expiration date (compatible with
L<DateTime::Format::RFC3339>) and should return a C<1> to verify the
connection, or C<0> to not.

  ...->get( $url, ..., verify_ssl => sub {
    my ($host, $port, $digest, $expire_date, $ok, $raw_cert) = @_;
    return 1 if int rand 2; # certificate is OK
    return 0;
  } );

The "okay?" boolean and raw certificate is also passed; these could be
used to allow certificates that other code was able to verify, or to
perform custom checks on the certificate using probably various routines
from L<Net::SSLeay>.

=back

=item B<getmore> I<callback> [ bufsize => n ]

A callback interface is provided to consume the response body, if
any. Generally this should only be present for response code C<2>.
The B<meta> line should be consulted for details on the MIME type
and encoding of the bytes; C<$body> in the following code may need
to be decoded.

  my $body = '';
  $gem->getmore(
      sub {
          my ( $buffer, $length ) = @_;
          $body .= $buffer;
          return 1;
      }
  );

The I<bufsize> parameter is as for B<get>.

=back

=head1 ACCESSORS

=over 4

=item B<code>

Code of the request, C<0> to C<6> inclusive. Pretty important, so is
also returned by B<get>. C<0> is an extension to the specification, and
is used for connection errors (e.g. host not found) and other problems
outside the gemini protocol.

=item B<content>

The content, if any. Raw bytes. Only if the B<code> is C<2>.

=item B<error>

The error message, if any.

=item B<host>

Host used for the request.

=item B<meta>

Gemini meta line. Use varies depending on the code.

=item B<port>

Port used for the request.

=item B<socket>

Socket to the server. May not be of much use after B<getmore> is
done with.

=item B<status>

Status of the request, a two digit number. Only set when the code is a
gemini response (that is, not an internal C<0> code).

=item B<uri>

URI used for the request. Probably could be used with any relative URL
returned from the server.

=back

=head1 BUGS

None known. But it is a rather incomplete module; that may be considered
a bug? The interface is very much subject to change.

=head1 SEE ALSO

L<gemini://gemini.circumlunar.space/docs/specification.gmi> (v0.16.1)

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
