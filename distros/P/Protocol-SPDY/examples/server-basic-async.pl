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

