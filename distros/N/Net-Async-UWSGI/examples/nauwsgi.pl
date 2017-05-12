#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::UWSGI::Server;
use Net::Async::HTTP;
use JSON::MaybeXS qw(JSON);
use Net::Async::HTTP::Connection;

my $loop = IO::Async::Loop->new;
my $srv = Net::Async::UWSGI::Server->new(
	backlog => 4096,
	path    => '/tmp/uwsgi.sock',
	mode    => '0666',
	on_request => sub {
		my ($req) = @_;
		Future->wrap(
			200, [], { success => JSON->true },
		)
	}
);
$loop->add($srv);

$srv->listening->then(sub {
	my $http = Net::Async::HTTP->new(
		max_connections_per_host => 0,
		pipeline => 0,
	);
	$loop->add($http);
	Future->needs_all(
		$http->GET(
			'http://uwsgi.localhost/request/get?x=123&y=test',
		),
		$http->POST(
			'http://uwsgi.localhost/request/post?x=123&y=test',
			'[ 1,2,3 ]',
			content_type => 'text/plain',
		),
		$loop->connect(
			host => 'uwsgi.localhost',
			service => 80,
			socktype => 'stream',
		)->then(sub {
			my $sock = shift;
			my $stream = IO::Async::Stream->new(
				handle => $sock,
				on_read => sub {
					my ($self, $buffref, $eof) = @_;
					$$buffref = '';
					$self->close if $eof;
					0
				}
			);
			$loop->add($stream);
			my $txt = '{"key":"value","nested":{"obj":"here"}}';
			$stream->write(join "\x0D\x0A",
				'POST /request/chunked HTTP/1.1',
				'Host: uwsgi.localhost',
				'Transfer-Encoding: chunked',
				'Content-Type: text/plain',
				'',
				(sprintf('%x', length $txt),
				$txt),
				'0',
				'',
				''
			);
		})
	);
})->get;
print "Ready\n";
# Devel::NYTProf
{
	eval {
		local $SIG{PIPE} = sub { warn "pipe\n" };
		DB::enable_profile() if DB->can('enable_profile');
#		IO::Async::Loop
		$loop->delay_future(after => 15)->get;
#		$loop->run;
		1
	} or warn "Failure - $@";
	if(DB->can('enable_profile')) {
		DB::disable_profile();
		DB::finish_profile();
	}
}
print "Done\n";
