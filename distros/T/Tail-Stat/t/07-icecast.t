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

		open EX,'<',File::Spec->catfile('t','ex','icecast') or die $!;
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

		is $s->getline => "enter:bbc32.mp3: 11\r\n";
		is $s->getline => "enter:dorognoe64.mp3: 89\r\n";
		is $s->getline => "enter:energy128.mp3: 190\r\n";
		is $s->getline => "enter:energy32.mp3: 53\r\n";
		is $s->getline => "enter:golosrossii64.mp3: 13\r\n";
		is $s->getline => "enter:kultura128.mp3: 41\r\n";
		is $s->getline => "enter:love128.mp3: 420\r\n";
		is $s->getline => "enter:love32.mp3: 255\r\n";
		is $s->getline => "enter:love64.mp3: 363\r\n";
		is $s->getline => "enter:mayak64.mp3: 122\r\n";
		is $s->getline => "enter:mv128.mp3: 198\r\n";
		is $s->getline => "enter:mv48.mp3: 41\r\n";
		is $s->getline => "enter:pioner128.mp3: 19\r\n";
		is $s->getline => "enter:pioner32.mp3: 3\r\n";
		is $s->getline => "enter:rrusia64.mp3: 13\r\n";
		is $s->getline => "enter:svoboda64.mp3: 206\r\n";
		is $s->getline => "enter:umor128.mp3: 337\r\n";
		is $s->getline => "enter:umor32.mp3: 84\r\n";
		is $s->getline => "enter:unost128.mp3: 68\r\n";
		is $s->getline => "enter:vesti64.mp3: 62\r\n";
		is $s->getline => "leave:bbc32.mp3: 3\r\n";
		is $s->getline => "leave:dorognoe64.mp3: 7\r\n";
		is $s->getline => "leave:energy128.mp3: 26\r\n";
		is $s->getline => "leave:energy32.mp3: 7\r\n";
		is $s->getline => "leave:golosrossii64.mp3: 1\r\n";
		is $s->getline => "leave:kultura128.mp3: 14\r\n";
		is $s->getline => "leave:love128.mp3: 74\r\n";
		is $s->getline => "leave:love32.mp3: 43\r\n";
		is $s->getline => "leave:love64.mp3: 99\r\n";
		is $s->getline => "leave:mayak64.mp3: 19\r\n";
		is $s->getline => "leave:mv128.mp3: 40\r\n";
		is $s->getline => "leave:mv48.mp3: 5\r\n";
		is $s->getline => "leave:pioner128.mp3: 4\r\n";
		is $s->getline => "leave:pioner32.mp3: 1\r\n";
		is $s->getline => "leave:rrusia64.mp3: 1\r\n";
		is $s->getline => "leave:svoboda64.mp3: 15\r\n";
		is $s->getline => "leave:umor128.mp3: 45\r\n";
		is $s->getline => "leave:umor32.mp3: 4\r\n";
		is $s->getline => "leave:unost128.mp3: 7\r\n";
		is $s->getline => "leave:vesti64.mp3: 8\r\n";
		is $s->getline => "online:bbc32.mp3: 8\r\n";
		is $s->getline => "online:dorognoe64.mp3: 82\r\n";
		is $s->getline => "online:energy128.mp3: 164\r\n";
		is $s->getline => "online:energy32.mp3: 46\r\n";
		is $s->getline => "online:golosrossii64.mp3: 12\r\n";
		is $s->getline => "online:kultura128.mp3: 27\r\n";
		is $s->getline => "online:love128.mp3: 346\r\n";
		is $s->getline => "online:love32.mp3: 212\r\n";
		is $s->getline => "online:love64.mp3: 264\r\n";
		is $s->getline => "online:mayak64.mp3: 103\r\n";
		is $s->getline => "online:mv128.mp3: 158\r\n";
		is $s->getline => "online:mv48.mp3: 36\r\n";
		is $s->getline => "online:pioner128.mp3: 15\r\n";
		is $s->getline => "online:pioner32.mp3: 2\r\n";
		is $s->getline => "online:rrusia64.mp3: 12\r\n";
		is $s->getline => "online:svoboda64.mp3: 191\r\n";
		is $s->getline => "online:umor128.mp3: 292\r\n";
		is $s->getline => "online:umor32.mp3: 80\r\n";
		is $s->getline => "online:unost128.mp3: 61\r\n";
		is $s->getline => "online:vesti64.mp3: 54\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		$ENV{ PERL5LIB } = join ':', @INC;
		exec qq($^X $bin -b$db -f -l$port --log-level=error -o usr -p$pid -w1 icecast x:$log);
	},
);

done_testing;

END {
	-f $_ and unlink $_ for grep { defined } $db,$log,$pid;
}

