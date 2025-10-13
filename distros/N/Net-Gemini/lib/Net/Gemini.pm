# -*- Perl -*-
#
# a Gemini protocol client
#
#   "The conjunction of Jupiter with one of the stars of Gemini, which
#   'we ourselves have seen' (1.6.343b30) has been dated in recent years
#   to December 337 BC."
#    -- Malcolm Wilson. Structure and Method in Aristotle's Meteorologica.

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
our $VERSION = '0.11';
use strict;
use warnings;
use Digest::SHA 'sha256_hex';
use Encode ();
use Exporter 'import';
use IO::Socket::IP;
use IO::Socket::SSL;
use Net::SSLeay;
use Parse::MIME 'parse_mime_type';

our @EXPORT_OK = qw(gemini_request);

sub _DEFAULT_BUFSIZE ()        { 4096 }
sub _DEFAULT_MAX_CONTENT ()    { 2097152 }
sub _DEFAULT_REDIRECTS ()      { 5 }
sub _DEFAULT_REDIRECT_SLEEP () { 1 }

sub code { $_[0]{_code} }    # 0..6 response code

sub content {
    $_[0]{_content};
}                            # NOTE only after certain calls and codes
sub error  { $_[0]{_error} } # error message for 0 code
sub host   { $_[0]{_host} }
sub ip     { $_[0]{_ip} }
sub meta   { $_[0]{_meta} }
sub mime   { $_[0]{_mime} }  # NOTE only after certain calls and codes
sub port   { $_[0]{_port} }
sub socket { $_[0]{_socket} }

sub status {
    $_[0]{_status};
}                            # two digit '1x', '2x', ... response code
sub uri { $_[0]{_uri} }

# see VERIFICATION below; the caller should supply a custom callback.
# the default is thus "Trust On Almost Any Use" (TOAAU) or similar to
# what gg(1) of gmid does
sub _verify_ssl { 1 }

# minimal method to get a resource (see also gemini_request)
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

    # VERIFICATION is based on the following though much remains up to
    # the caller to manage
    # gemini://makeworld.space/gemlog/2020-07-03-tofu-rec.gmi
    # gemini://alexschroeder.ch/page/2020-07-20%20Does%20a%20Gemini%20certificate%20need%20a%20Common%20Name%20matching%20the%20domain%3F
    eval {
        $obj{_socket} = IO::Socket::IP->new(
            ( exists $param{family} ? ( Domain => $param{family} ) : () ),
            PeerAddr => $obj{_host},
            PeerPort => $obj{_port},
            Proto    => 'tcp'
        ) or die $!;
        $obj{_ip} = $obj{_socket}->peerhost;
        IO::Socket::SSL->start_SSL(
            $obj{_socket},
            SSL_hostname => $obj{_host},    # SNI
            ( $param{tofu} ? ( SSL_verifycn_scheme => 'none' ) : () ),
            SSL_verify_callback => sub {
                my ( $ok, $ctx_store, $certname, $error, $cert, $depth ) = @_;
                if ( $depth != 0 ) {
                    return 1 if $param{tofu};
                    return $ok;
                }
                my $digest = ( $param{verify_ssl} || \&_verify_ssl )->(
                    {   host   => $obj{_host},
                        port   => $obj{_port},
                        cert   => $cert,         # warning, memory address!
                                                 # compatible with certID function of amfora
                        digest =>
                          uc( sha256_hex( Net::SSLeay::X509_get_X509_PUBKEY($cert) ) ),
                        ip        => $obj{_ip},
                        notBefore => Net::SSLeay::P_ASN1_TIME_get_isotime(
                            Net::SSLeay::X509_get_notBefore($cert)
                        ),
                        notAfter => Net::SSLeay::P_ASN1_TIME_get_isotime(
                            Net::SSLeay::X509_get_notAfter($cert)
                        ),
                        okay => $ok,
                    }
                );
            },
            ( exists $param{ssl} ? %{ $param{ssl} } : () ),
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

    # get the STATUS SPACE header response (and, probably, more)
    $obj{_buf} = '';
    while (1) {
        my $n = sysread $obj{_socket}, my $buf,
          $param{bufsize} || _DEFAULT_BUFSIZE;
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
    # NOTE this is sloppy; there are fewer "full two digit status codes"
    # defined in the appendix, e.g. only 10, 11, 20, 30, 31, 40, ...
    # on the other hand, this supports any new extensions to the
    # existing numbers
    if ( $obj{_buf} =~ m/^(([1-6])[0-9])[ ]/ ) {
        @obj{qw(_status _code)} = ( $1, $2 );
        substr $obj{_buf}, 0, 3, '';
    } else {
        @obj{qw(_code _error)} = (
            0,
            "invalid response " . sprintf "%vx",
            substr $obj{_buf},
            0, 3
        );
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
                $obj{_meta} = 'text/gemini;charset=utf-8' if $obj{_code} == 2;
            } else {
                eval {
                    $obj{_meta} =
                      Encode::decode( 'UTF-8', $obj{_meta}, Encode::FB_CROAK );
                    1;
                } or do {
                    @obj{qw(_code _error)} = ( 0, "failed to decode meta: $@" );
                    goto BLESSING;
                };
                # another special case (RFC 2045 says that these things
                # are not case sensitive, hence the (?i) despite the
                # gemini specification saying "text/")
                if (    $obj{_code} == 2
                    and $obj{_meta} =~ m{^(?i)text/}
                    and $obj{_meta} !~ m/(?i)charset=/ ) {
                    $obj{_meta} .= ';charset=utf-8';
                }
            }
            substr $obj{_buf}, 0, $len + 2, '';    # +2 for the \r\n
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

# utility function that handles redirects and various means of content
# collection
sub gemini_request {
    my ( $source, %options ) = @_;
    $options{max_redirects} = _DEFAULT_REDIRECTS
      unless exists $options{max_redirects};
    $options{redirect_delay} = _DEFAULT_REDIRECT_SLEEP
      unless exists $options{redirect_delay};
    $options{max_size} = _DEFAULT_MAX_CONTENT
      unless exists $options{max_size};

    my ( $gem, $code );
    my $redirects = 0;
  REQUEST:
    ( $gem, $code ) = Net::Gemini->get( $source,
        ( exists $options{param} ? %{ $options{param} } : () ) );
    if ( $code == 2 ) {
        my $len     = length $gem->{_buf};
        my $bufsize = $options{bufsize} || _DEFAULT_BUFSIZE;
        # this can make uninit noise for a meta of ";" which might be
        # worth an upstream patch?
        $gem->{_mime} = [ parse_mime_type( $gem->meta ) ];
        if ( exists $options{content_callback} ) {
            if ($len) {
                $options{content_callback}->( $gem->{_buf}, $len, $gem )
                  or goto CLEANUP;
            }
            while (1) {
                my $buf;
                $len = sysread $gem->{_socket}, $buf, $bufsize;
                if ( !defined $len ) {
                    die "sysread failed: $!\n";
                } elsif ( $len == 0 ) {
                    last;
                }
                $options{content_callback}->( $buf, $len, $gem ) or goto CLEANUP;
            }
        } else {
            if ($len) {
                if ( $len > $options{max_size} ) {
                    $gem->{_content} = substr $gem->{_buf}, 0, $options{max_size};
                    @{$gem}{qw(_code _error)} = ( 0, 'max_size' );
                    goto CLEANUP;
                }
                $gem->{_content} = $gem->{_buf};
                $options{max_size} -= $len;
            }
            while (1) {
                my $buf;
                $len = sysread $gem->{_socket}, $buf, $bufsize;
                if ( !defined $len ) {
                    die "sysread failed: $!\n";
                } elsif ( $len == 0 ) {
                    last;
                }
                if ( $len > $options{max_size} ) {
                    $gem->{_content} .= substr $buf, 0, $options{max_size};
                    @{$gem}{qw(_code _error)} = ( 0, 'max_size' );
                    goto CLEANUP;
                }
                $gem->{_content} .= $buf;
                $options{max_size} -= $len;
            }
        }
    } elsif ( $code == 3 and ++$redirects <= $options{max_redirects} ) {
        # a '31' permanent redirect should result in us not requesting
        # the old URL again, but that would require more code here for
        # something that is probably rare
        my $new = $gem->{_meta};
        $source = URI->new_abs( $new, $gem->{_uri} );
        select( undef, undef, undef, $options{redirect_delay} );
        goto REQUEST;
    }
  CLEANUP:
    undef $gem->{_buf};
    close $gem->{_socket};
    return $gem, $code;
}

# drain what remains (if anything) via a callback interface. assumes
# that a ->get call has been made
sub getmore {
    my ( $self, $callback, %param ) = @_;

    my $len = length $self->{_buf};
    if ($len) {
        $callback->( $self->{_buf}, $len ) or return;
        undef $self->{_buf};
    }

    my $bufsize = $param{bufsize} || _DEFAULT_BUFSIZE;
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
    case(2) { ... $gem->meta and collect on the socket ... }
    case(3) { ... $gem->meta as redirect ... }
    case(4) { ... $gem->meta as temporary failure ... }
    case(5) { ... $gem->meta as permanent failure ... }
    case(6) { ... $gem->meta as client certificate message ... }
  }


=head1 DESCRIPTION

This module implements code that may help implement a gemini protocol
client in Perl.

=head2 CAVEATS

It's a pretty beta module.

The default SSL verification is more or less to accept the connection;
this is perhaps not ideal. The caller will need to implement TOFU or a
similar means of verifying the other end.

L<gemini://makeworld.space/gemlog/2020-07-03-tofu-rec.gmi>

=head1 FUNCTION

=over 4

=item B<gemini_request> I<URI> [ options ... ]

A utility function that is not exported by default; it calls the B<get>
method and handles redirects and the collection of content, if any.

  use Net::Gemini 'gemini_request';
  my ( $gem, $code ) = gemini_request( 'gemini://...', ... );

A code C<2> will result in the B<mime> accessor being populated with the
Content-Type by way of the C<parse_mime_type> function from L<Parse::MIME>.

A notable difference here is that a code of C<3> indicates that too many
redirects were encountered, not that there was a redirect. This should
be considered an error.

The socket will be closed when this call ends.

Options include:

=over 4

=item I<bufsize> => I<strictly-positive-integer>

Buffer size to use for reads from the socket. 4096 by default.

=item I<content_callback> => I<code-reference>

Custom callback to handle one or more portions of the request content
with, same as the B<getmore> interface. If a callback is not provided
the content will be collected into the object via the B<content>
accessor. The callback is given the current buffer (raw), the length of
that buffer, and a reference to the gemini object.

  gemini_request( $uri, content_callback => sub {
    my ( $buffer, $length, $gem ) = @_;
    ...
    return 1;
  });

Processing will stop if the callback returns a false value.

=item B<max_size> => I<strictly-positive-integer>

Maximum content size to collect into B<content>. Ignored if a custom
callback is provided. The code will be zero and the error will be
C<max_size> and the status will start with C<2> and the content will be
truncated if the response is larger than permitted.

=item I<max_redirects> => I<strictly-positive-integer>

How many redirections should be followed. C<5> is the default.

=item I<redirect_delay> => I<floating-point>

How long to delay between redirects, by default C<1> second. There is a
delay by default because gemini servers or firewalls may rate limit
requests, or the gemini server simply may not have much CPU available.

=item I<param> => I<hash-reference>

Parameters that will be passed to the B<get> method.

=back

=back

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

For code C<2> responses the response body may be split between I<_buf>
and whatever remains unread in the socket, if anything, hence the
B<getmore> method or the B<gemini_request> utility function.

Parameters include:

=over 4

=item B<bufsize> => I<strictly-positive-integer>

Size of buffer to use for requests, 4096 by default. Note that a naughty
server may return data in far smaller increments than this.

=item B<ssl> => { params }

Passes the given parameters to the L<IO::Socket::SSL> constructor. These
could be used to configure e.g. the C<SSL_verify_mode> or to set a
verification callback, or to specify a custom SNI host via
C<SSL_hostname>.

C<Timeout> can be used to set a connect timeout on the socket. However,
a server could wedge at any point following, so it may be necessary to
wrap a B<get> request with the C<alarm> function or similar.

=item B<tofu> => I<boolean>

If true, only the leaf certificate will be checked. Otherwise, the full
certificate chain will be verified by default, which is probably not
what you want when trusting the very first leaf certificate seen.

Also with this flag set hostname verification is turned off; the caller
can manage C<SSL_verifycn_scheme> and possibly C<SSL_verifycn_name> via
the B<ssl> param if this needs to be customized.

=item B<verify_ssl> => code-reference

Custom callback function to handle SSL verification. The default is to
accept the connection (Trust On All Uses), which is perhaps not ideal.
The callback is passed a hash reference containing various information
about the certificate and connection.

  ...->get( $url, ..., verify_ssl => sub {
    my ($param) = @_;
    return 1 if int rand 2; # certificate is OK
    return 0;
  } );

Note that some have argued that under TOFU one should not verify the
hostname nor the dates (notBefore, notAfter) of the certificate, only to
accept the first certificate presented as-is, like SSH does, and to use
that certificate thereafter. This has plusses and minuses.

See C<bin/gmitool> for how C<verify_ssl> might be used in a client.

In module version 0.08 the format of the digest (fingerprint) changed to
be compatible with the amfora gemini client.

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

Or you can use the faster hash internals, which are not expected to change.

=over 4

=item B<code>

Code of the request, C<0> to C<6> inclusive. Pretty important, so is
also returned by B<get>. C<0> is an extension to the specification, and
is used for connection errors (e.g. host not found) and other problems
outside the gemini protocol.

=item B<content>

The content, if any. Raw bytes. Only if the B<code> is C<2> and a
suitable B<gemini_request> call has been made.

=item B<error>

The error message, if any.

=item B<host>

Host used for the request.

=item B<ip>

IP address used for the request.

=item B<meta>

Gemini meta line. Use varies depending on the code.

=item B<mime>

Only set by B<gemini_request> for C<2> code responses; contains an array
reference of return values from the C<parse_mime_type> function of
L<Parse::MIME>.

=item B<port>

Port used for the request.

=item B<socket>

Socket to the server. May not be of much use after B<getmore> is done
with, or after B<gemini_request>.

=item B<status>

Status of the request, a two digit number. Only set when the code is a
gemini response (that is, not an internal C<0> code).

=item B<uri>

URI used for the request. Probably could be used with any relative URL
returned from the server.

=back

=head1 BUGS

None known. But it is a somewhat incomplete module, and the
specification may change, too.

=head1 SEE ALSO

L<gemini://gemini.circumlunar.space/docs/specification.gmi> (v0.16.1)

L<gemini://gemini.thebackupbox.net/test/torture>

RFC 2045

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
