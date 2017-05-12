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
	SSL_npn_protocols => [
		'spdy/3.1',
		# Normally you'd also list HTTP here,
		# but since we're only supporting SPDY
		# in this example, we don't do that.
		# 'http/1.1'
	],
	SSL_cert_file => 'certs/examples.crt',
	SSL_key_file => 'certs/examples.key',
	SSL_ca_path => 'certs/ProtocolSPDYCA',
	SSL_ciphers => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-RC4-SHA:ECDHE-RSA-AES128-SHA:RC4:HIGH:!MD5:!aNULL:!EDH',
	on_accept => sub {
		my $sock = shift;
		print "Client connecting from " . join(':', $sock->peerhost, $sock->peerport) . ", we're using " . $sock->next_proto_negotiated . "\n";
		die "Wrong protocol" unless $sock->next_proto_negotiated eq 'spdy/3';
		my $stream = IO::Async::Stream->new(handle => $sock);
		my $spdy = Protocol::SPDY::Server->new;
		# Pass all writes directly to the stream
		$spdy->{on_write} = $stream->curry::write;
		$spdy->subscribe_to_event(
			stream => sub {
				my $ev = shift;
				my $stream = shift;
				print "We have a new stream:\n";
				$stream->closed->on_fail(sub {
					warn "We had an error: " . shift;
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

				my $input = $req->as_string("\n");
				my $output = <<"HTML";
<!DOCTYPE html>
<html>
 <head>
  <title>Example SPDY server</title>
  <style type="text/css">
* { margin: 0; padding: 0 }
h1 { color: #ccc; background: #333 }
p { padding: 0.5em }
  </style>
 </head>
 <body>
  <h1>Protocol::SPDY example server</h1>
  <p>
   Your request was parsed as:
  </p>
  <pre>
$input
  </pre>
 </body>
</html>
HTML
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

