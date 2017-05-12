#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Test::More;
use Test::TCP;

plan skip_all => 'MS Windows'
	if $^O eq 'MSWin32';

my $bin = File::Spec->catfile('bin','tstatd');
my $db  = File::Spec->catfile('t','db');
my $log = File::Spec->catfile('t','log');
my $pid = File::Spec->catfile('t','pid');

die 'tstatd not found' unless -f $bin && -x _;

-f $_ and unlink $_ for $db,$log,$pid;

$SIG{ ALRM } = sub { die 'test timed out' };

open FH,'>',$log or die $!; close FH;

test_tcp(
	client => sub {
		my $s = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => shift );

		alarm 3;
		print $s "zones\n";
		is $s->getline => "a:x\r\n";
		alarm 0;

		open EX,'<',File::Spec->catfile('t','ex','nginx') or die $!;
		open FH,'>>',$log or die $!;
		print FH do { local $/=<EX> };
		close EX; close FH;
		sleep 3;

		my $len = (stat $log)[7];

		alarm 3;
		print $s "files x\n";
		like $s->getline => qr"^$len:$len:/.*/t/log";
		alarm 0;

		alarm 3;
		print $s "stats x\n";
		is $s->getline => "http_byte: 4849289\r\n";
		is $s->getline => "http_method_get: 190\r\n";
		is $s->getline => "http_method_head: 0\r\n";
		is $s->getline => "http_method_inc: 0\r\n";
		is $s->getline => "http_method_other: 3\r\n";
		is $s->getline => "http_method_post: 12\r\n";
		is $s->getline => "http_request: 205\r\n";
		is $s->getline => "http_status_1xx: 0\r\n";
		is $s->getline => "http_status_200: 116\r\n";
		is $s->getline => "http_status_201: 3\r\n";
		is $s->getline => "http_status_204: 61\r\n";
		is $s->getline => "http_status_2xx: 180\r\n";
		is $s->getline => "http_status_304: 3\r\n";
		is $s->getline => "http_status_3xx: 3\r\n";
		is $s->getline => "http_status_404: 13\r\n";
		is $s->getline => "http_status_499: 2\r\n";
		is $s->getline => "http_status_4xx: 15\r\n";
		is $s->getline => "http_status_500: 2\r\n";
		is $s->getline => "http_status_502: 1\r\n";
		is $s->getline => "http_status_503: 2\r\n";
		is $s->getline => "http_status_504: 2\r\n";
		is $s->getline => "http_status_5xx: 7\r\n";
		is $s->getline => "http_version_0_9: 3\r\n";
		is $s->getline => "http_version_1_0: 22\r\n";
		is $s->getline => "http_version_1_1: 175\r\n";
		is $s->getline => "http_version_2_0: 5\r\n";
		is $s->getline => "last_http_byte: 4849289\r\n";
		is $s->getline => "last_http_request: 205\r\n";
		is $s->getline => "malformed_request: 0\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		$ENV{ PERL5LIB } = join ':', @INC;
		exec qq($^X $bin -b$db -f -l$port --log-level=error -o clf -p$pid -w1 nginx x:$log);
	},
);

done_testing;

END {
	-f $_ and unlink $_ for grep { defined } $db,$log,$pid;
}

