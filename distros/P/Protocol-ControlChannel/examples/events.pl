#!/usr/bin/env perl
use strict;
use warnings;
use Protocol::ControlChannel;
use IO::Async::Loop;
my $loop = IO::Async::Loop->new;
$loop->listen(
	addr => {
		host => 'localhost',
		family => 'inet',
		socktype => 'stream',
		port => 0,
	},
	on_listen => sub {
		my $sock = shift;
		warn "listening on " . $sock->sockport;
		run_connect($sock->sockport);
	},
	on_stream => sub {
		my $stream = shift;
		my $remote = join ':', map $stream->read_handle->$_, qw(peerhost peerport);
		warn "Incoming request from $remote\n";
		my $cc = Protocol::ControlChannel->new;
		$stream->configure(
			on_read => sub {
				my (undef, $buffer, $eof) = @_;
				while(my $frame = $cc->extract_frame($buffer)) {
					warn "Server: recv frame from $remote: " . $frame->{key} . " => " . $frame->{value} . "\n";
				}
				warn "Client $remote has gone away" if $eof;
				return 0;
			}
		);
		$stream->write($cc->create_frame(key => 'value'));
		$loop->add($stream);
	}
);
sub run_connect {
	my $port = shift;
	warn "connecting to $port\n";
	$loop->connect(
		addr => {
			host => 'localhost',
			family => 'inet',
			socktype => 'stream',
			port => $port,
		},
	)->on_done(sub {
		warn "client stream: @_";
		my $sock = shift;
		my $stream = IO::Async::Stream->new(handle => $sock);
		my $cc = Protocol::ControlChannel->new;
		$stream->configure(
			on_read => sub {
				my (undef, $buffer, $eof) = @_;
				while(my $frame = $cc->extract_frame($buffer)) {
					warn "Have frame: " . $frame->{key} . " => " . $frame->{value} . "\n";
				}
				warn "eof\n" if $eof;
				return 0;
			}
		);
		$stream->write($cc->create_frame(client_key => 'client val'));
		$loop->add($stream);
	});
}
$loop->run;
#	ok(my $data = $cc->create_frame(@$case), 'create a frame');
#	ok(length($data), 'data is non-empty');
#	ok(my $frame = $cc->extract_frame(\$data), 'extract that frame');
#	is(length($data), 0, 'data is now empty');
#	is($frame->{key}, $case->[0], 'key is correct');
#	is($frame->{value}, $case->[1], 'value is correct');
