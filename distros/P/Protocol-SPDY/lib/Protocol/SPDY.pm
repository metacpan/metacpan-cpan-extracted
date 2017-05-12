package Protocol::SPDY;
# ABSTRACT: Support for the SPDY protocol
use strict;
use warnings;

our $VERSION = '1.001';

=head1 NAME

Protocol::SPDY - abstract support for the SPDY protocol

=head1 VERSION

version 1.001

=head1 SYNOPSIS

 use Protocol::SPDY;

=cut

# Pull in all the required pieces
use Protocol::SPDY::Constants ':all';

# Helpers
use curry;
use Future;

# Support for deflate/gzip
use Protocol::SPDY::Compress;

# Basic frame wrangling
use Protocol::SPDY::Frame;
use Protocol::SPDY::Frame::Control;
use Protocol::SPDY::Frame::Data;

# Specific frame types
use Protocol::SPDY::Frame::Control::SETTINGS;
use Protocol::SPDY::Frame::Control::SYN_STREAM;
use Protocol::SPDY::Frame::Control::SYN_REPLY;
use Protocol::SPDY::Frame::Control::RST_STREAM;
use Protocol::SPDY::Frame::Control::PING;
use Protocol::SPDY::Frame::Control::GOAWAY;
use Protocol::SPDY::Frame::Control::HEADERS;
use Protocol::SPDY::Frame::Control::WINDOW_UPDATE;
use Protocol::SPDY::Frame::Control::CREDENTIAL;

# Stream management
use Protocol::SPDY::Stream;

# Client/server logic
use Protocol::SPDY::Server;
use Protocol::SPDY::Client;
use Protocol::SPDY::Tracer;

1;

__END__

=head1 DESCRIPTION

Provides an implementation for the SPDY protocol at an abstract (in-memory buffer) level.

This module will B<not> initiate or receive any network connections on its own.

It is intended for use as a base on which to build web server/client implementations
using whichever transport mechanism is appropriate.

This means that if you want to add SPDY client or server support to your code, you'll
need a transport as well:

=over 4

=item * L<Net::Async::SPDY::Server> - serve SPDY requests using L<IO::Async>

=item * L<Net::Async::SPDY::Client> - connect to SPDY servers using L<IO::Async>
(although once this is stable support may be added to L<Net::Async::HTTP>,
see L<#74387|https://rt.cpan.org/Ticket/Display.html?id=74387> for progress on this).

=back

Eventually L<POE> or L<Reflex> implementations may arrive, if someone more familiar
with those frameworks takes an interest.

On the server side, it should be possible to incorporate this as a plugin for
Plack/PSGI so that any PSGI-compatible web application can support basic SPDY
requests. Features that plain HTTP doesn't support, such as server push or
prioritisation, may require PSGI extensions. Although I don't use PSGI myself,
I'd be happy to help add any necessary support required to allow these extra
features - the L<Web::Async> framework may be helpful as a working example for
SPDY-specific features.

Primary focus is on providing server-side SPDY implementation for use with
browsers such as Chrome and Firefox (at the time of writing, Firefox has had
optional support for SPDY since version 11, and IE11 is also rumoured to
provide SPDY/3 support). The Android browser has supported SPDY for some time (since
Android 3.0+?).

See the L</EXAMPLES> section below for some basic code examples.

=head1 IMPLEMENTATION CONSIDERATIONS

The information in L<http://www.chromium.org/spdy> may be useful when implementing clients
(browsers).

See the L</COMPONENTS> section for links to the main classes you'll be needing
if you're writing your own transport.

=head2 UPGRADING EXISTING HTTP OR HTTPS CONNECTIONS

You can inform a browser that SPDY is available through the Alternate-Protocol HTTP
header:

 Alternate-Protocol: <port>:<protocol>

For example:

 Alternate-Protocol: 2443:spdy/3

This applies both to HTTP and HTTPS.

If the browser is already connected to the server using TLS, the ALPN or NPN mechanisms can
be used to indicate that SPDY is available. Currently this requires openssl-1.0.2 or later
for ALPN, although the NPN extension works in older openssl versions (see
L<http://www.ietf.org/id/draft-agl-tls-nextprotoneg-00.txt> for details).

An Alternate-Protocol header with more than one protocol might look as follows:

 Alternate-Protocol: 2443:spdy/3,443:npn-spdy/3

=head2 PACKET SEQUENCE

=over 4

=item * Typically both sides would send a SETTINGS packet first.

=item * This would be followed by SYN_STREAM from the client corresponding to the
initial HTTP request.

=item * The server responds with SYN_REPLY containing the HTTP response headers.

=item * Either side may send data frames for active streams until the FIN
flag is set on a packet for that stream

=item * A request is complete when the stream on both sides is in FIN state.

=item * Further requests may be issued using SYN_STREAM

=item * If some time has passed since the last packet from the other side, a PING frame
may be sent to verify that the connection is still active.

=back

=head1 COMPONENTS

Further documentation can be found in the following modules:

=over 4

=item * L<Protocol::SPDY::Server> - handle the server side of the connection. This
would typically be used for incorporating SPDY support into a server.

=item * L<Protocol::SPDY::Client> - handle the client side of the connection. This
could be used for making SPDY requests as a client.

=item * L<Protocol::SPDY::Tracer> - if you want to check the packets that are being
generated, try this class for basic packet-level debugging.

=item * L<Protocol::SPDY::Stream> - handling for 'streams', which are somewhat
analogous to individual HTTP requests

=item * L<Protocol::SPDY::Frame> - generic frame class

=item * L<Protocol::SPDY::Frame::Control> - specific subclass for control frames

=item * L<Protocol::SPDY::Frame::Data> - specific subclass for data frames

=back

Each control frame type has its own class, see L<Protocol::SPDY::Frame::Control/TYPES>
for links.

=head1 EXAMPLES

SSL/TLS next protocol negotiation for SPDY/3 with HTTP/1.1 fallback:

 #!/usr/bin/env perl
 use strict;
 use warnings;
 
 # Simple example showing NPN negotiation using IO::Async::SSL.
 # The same SSL_* parameters are supported by IO::Socket::SSL.
 
 use IO::Socket::SSL qw(SSL_VERIFY_NONE);
 use IO::Async::Loop;
 use IO::Async::SSL;
 
 my $loop = IO::Async::Loop->new;
 $loop->SSL_listen(
 	addr => {
 		family   => "inet",
 		socktype => "stream",
 		port     => 0,
 	},
 	SSL_npn_protocols => [ 'spdy/3', 'http1.1' ],
 	SSL_cert_file => 'certs/examples.crt',
 	SSL_key_file => 'certs/examples.key',
 	on_stream => sub {
 		my $sock = shift;
 		print "Client connected to $sock, we're using " . $sock->write_handle->next_proto_negotiated . "\n";
 	},
 	on_ssl_error => sub { die "ssl error: @_"; },
 	on_connect_error => sub { die "conn error: @_"; },
 	on_resolve_error => sub { die "conn error: @_"; },
 	on_listen => sub {
 		my $sock = shift;
 		my $port = $sock->sockport;
 		print "Listening on port $port\n";
 		$loop->SSL_connect(
 			addr => {
 				family   => "inet",
 				socktype => "stream",
 				port     => $port,
 			},
 			SSL_npn_protocols => [ 'spdy/3', 'http1.1' ],
 			SSL_verify_mode => SSL_VERIFY_NONE,
 			on_connected => sub {
 				my $sock = shift;
 				print "Connected to $sock using " . $sock->next_proto_negotiated . "\n";
 				$loop->stop;
 			},
 			on_ssl_error => sub { die "ssl error: @_"; },
 			on_connect_error => sub { die "conn error: @_"; },
 			on_resolve_error => sub { die "conn error: @_"; },
 		);
 
 	},
 );
 $loop->run;

Show frames (one per line) from traffic capture. Note that this needs to be
post-TLS decryption, without any TCP/IP headers. Also, for tracing traffic
on a live application, you'd hook the C<send_frame> and C<receive_frame>
events instead.

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use Protocol::SPDY;
 
 my $spdy = Protocol::SPDY::Tracer->new;
 $spdy->subscribe_to_event(
 	receive_frame => sub { print $_[1] . "\n" }
 );
 local $/ = \1024;
 while(<>) {
 	$spdy->on_read($_);
 }

An L<IO::Async>-based server which reports the originating request. This
should be just enough to implement a basic server for other frameworks
- see L<Net::Async::SPDY::Server> for a more complete implementation:

 #!/usr/bin/env perl
 use strict;
 use warnings;
 
 # Set the PROTOCOL_SPDY_LISTEN_PORT env var if you want to listen on a specific port.
 
 use Protocol::SPDY;
 
 use HTTP::Request;
 use HTTP::Response;
 
 use IO::Socket::SSL qw(SSL_VERIFY_NONE);
 use IO::Async::Loop;
 use IO::Async::SSL;
 use IO::Async::Stream;
 
 my $loop = IO::Async::Loop->new;
 $loop->SSL_listen(
 	addr => {
 		family   => "inet",
 		socktype => "stream",
 		port     => $ENV{PROTOCOL_SPDY_LISTEN_PORT} || 0,
 	},
 	SSL_npn_protocols => [ 'spdy/3' ],
 	SSL_cert_file => 'certs/examples.crt',
 	SSL_key_file => 'certs/examples.key',
 	SSL_ca_path => 'certs/ProtocolSPDYCA',
 	on_accept => sub {
 		my $sock = shift;
 		print "Client connecting from " . join(':', $sock->peerhost, $sock->peerport) . ", we're using " . $sock->next_proto_negotiated . "\n";
 
 		my $stream = IO::Async::Stream->new(handle => $sock);
 		my $spdy = Protocol::SPDY::Server->new;
 		# Pass all writes directly to the stream
 		$spdy->{on_write} = $stream->curry::write;
 		$spdy->subscribe_to_event(
 			stream => sub {
 				my $ev = shift;
 				my $stream = shift;
 				$stream->closed->on_fail(sub {
 					die "We had an error: " . shift;
 				});
 				my $hdr = { %{$stream->received_headers} };
 				my $req = HTTP::Request->new(
 					(delete $hdr->{':method'}) => (delete $hdr->{':path'})
 				);
 				$req->protocol(delete $hdr->{':version'});
 				my $scheme = delete $hdr->{':scheme'};
 				my $host = delete $hdr->{':host'};
 				$req->header('Host' => $host);
 				$req->header($_ => delete $hdr->{$_}) for keys %$hdr;
 				print $req->as_string("\n");
 
 				# You'd probably raise a 400 response here, but it's a conveniently
 				# easy way to demonstrate our reset handling
 				return $stream->reset(
 					'REFUSED'
 				) if $req->uri->path =~ qr{^/reset/refused};
 
 				my $response = HTTP::Response->new(
 					200 => 'OK', [
 						'Content-Type' => 'text/html; charset=UTF-8',
 					]
 				);
 				$response->protocol($req->protocol);
 
 				# Just dump the original request
 				my $output = $req->as_string("\n");
 
 				# At the protocol level we only care about bytes. Make sure that's all we have.
 				$output = Encode::encode('UTF-8' => $output);
 				$response->header('Content-Length' => length $output);
 				my %hdr = map {; lc($_) => ''.$response->header($_) } $response->header_field_names;
 				delete @hdr{qw(connection keep-alive proxy-connection transfer-encoding)};
 				$stream->reply(
 					fin => 0,
 					headers => {
 						%hdr,
 						':status'  => join(' ', $response->code, $response->message),
 						':version' => $response->protocol,
 					}
 				);
 				$stream->send_data(substr $output, 0, 1024, '') while length $output;
 				$stream->send_data('', fin => 1);
 			}
 		);
 		$stream->configure(
 			on_read => sub {
 				my ( $self, $buffref, $eof ) = @_;
 				# Dump everything we have - could process in chunks if you
 				# want to be fair to other active sessions
 				$spdy->on_read(substr $$buffref, 0, length($$buffref), '');
 
 				if( $eof ) {
 					print "EOF\n";
 				}
 
 				return 0;
 			}
 		);
 		$loop->add($stream);
 	},
 	on_ssl_error => sub { warn "ose: @_\n"; die "ssl error: @_"; },
 	on_connect_error => sub { die "conn error: @_"; },
 	on_resolve_error => sub { die "resolve error: @_"; },
 	on_listen => sub {
 		my $sock = shift;
 		my $port = $sock->sockport;
 		print "Listening on port $port\n";
 	},
 );
 
 # Run until Ctrl-C or error
 $loop->run;

L<IO::Async>-based client for simple GET requests, again
L<Net::Async::SPDY::Client> would be the place to look for a real client
implementation:

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use 5.010;
 #use Carp::Always;
 
 # Usage: perl client-async.pl https://spdy-test.perlsite.co.uk/index.html
 
 use Protocol::SPDY;
 
 use HTTP::Request;
 use HTTP::Response;
 
 use IO::Socket::SSL qw(SSL_VERIFY_NONE);
 use IO::Async::Loop;
 use IO::Async::SSL;
 use IO::Async::Stream;
 use URI;
 
 my $loop = IO::Async::Loop->new;
 my $uri = URI->new(shift @ARGV or die 'no URL?');
 warn $uri->host;
 $loop->SSL_connect(
 	addr => {
 		family   => "inet",
 		socktype => "stream",
 		host     => $uri->host,
 		port     => $uri->port || 'https',
 	},
 	SSL_alpn_protocols => [
 		'spdy/3.1',
 		'spdy/3',
 	],
 	SSL_verify_mode => SSL_VERIFY_NONE,
 	on_connected => sub {
 		my $sock = shift;
 		my $proto = $sock->alpn_selected;
 		print "Connected to " . join(':', $sock->peerhost, $sock->peerport) . ", we're using " . $proto . "\n";
 		die "Wrong protocol" unless $proto =~ /^spdy/;
 		my $stream = IO::Async::Stream->new(handle => $sock);
 		my $spdy = Protocol::SPDY::Client->new;
 		# Pass all writes directly to the stream
 		$spdy->{on_write} = $stream->curry::write;
 		$stream->configure(
 			on_read => sub {
 				my ( $self, $buffref, $eof ) = @_;
 				# Dump everything we have - could process in chunks if you
 				# want to be fair to other active sessions
 				$spdy->on_read(substr $$buffref, 0, length($$buffref), '');
 
 				if( $eof ) {
 					print "EOF\n";
 				}
 
 				return 0;
 			}
 		);
 		my $req = $spdy->create_stream(
 		);
 		$req->subscribe_to_event(data => sub {
 			my ($ev, $data) = @_;
 			say $data;
 		});
 		$req->replied->on_done(sub {
 			my $hdr = $req->received_headers;
 			say join ' ', map delete $hdr->{$_}, qw(:version :status);
 			for(sort keys %$hdr) {
 				# Camel-Case the header names
 				(my $k = $_) =~ s{(?:^|-)\K(\w)}{\U$1}g;
 				say join ': ', $k, $hdr->{$_};
 			}
 			say '';
 			# We may get extra headers, stash them until after data
 			$req->subscribe_to_event(headers => sub {
 				my ($ev, $headers) = @_;
 				# ...
 			});
 		});
 		$req->remote_finished->on_done(sub { $loop->stop });
 		$req->start(
 			fin     => 1,
 			headers => {
 				':method'  => 'GET',
 				':path'    => '/' . $uri->path,
 				':scheme'  => $uri->scheme,
 				':host'    => $uri->host . ($uri->port ? ':' . $uri->port : ''),
 				':version' => 'HTTP/1.1',
 			}
 		);
 		$loop->add($stream);
 	},
 	on_ssl_error => sub { die "ssl error: @_"; },
 	on_connect_error => sub { die "conn error: @_"; },
 	on_resolve_error => sub { die "resolve error: @_"; },
 	on_listen => sub {
 		my $sock = shift;
 		my $port = $sock->sockport;
 		print "Listening on port $port\n";
 	},
 );
 
 # Run until Ctrl-C or error
 $loop->run;

Other examples are in the C<examples/> directory.

=head1 SEE ALSO

Since the protocol is still in flux, it may be advisable to keep an eye on
L<http://www.chromium.org/spdy>. The preliminary work on HTTP/2.0 protocol
was at the time of writing also based on SPDY/3, so the IETF page is likely
to be a useful resource: L<http://tools.ietf.org/wg/httpbis/>.

The only other implementation I've seen so far for Perl is L<Net::SPDY>, which
as of 0.01_5 is still a development release but does come with a client and
server example which should make it easy to get started with.

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
