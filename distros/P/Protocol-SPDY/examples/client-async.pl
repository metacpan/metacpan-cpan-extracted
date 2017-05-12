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

