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

		open EX,'<',File::Spec->catfile('t','ex','spamd') or die $!;
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
		is $s->getline => "clean_bytes: 538823\r\n";
		is $s->getline => "clean_messages: 24\r\n";
		is $s->getline => "last_clean_bytes: 538823\r\n";
		is $s->getline => "last_clean_elapsed: 87.5\r\n";
		is $s->getline => "last_clean_messages: 24\r\n";
		is $s->getline => "last_clean_rate: -328.3\r\n";
		is $s->getline => "last_spam_bytes: 3345150\r\n";
		is $s->getline => "last_spam_elapsed: 1608.2\r\n";
		is $s->getline => "last_spam_messages: 490\r\n";
		like $s->getline => qr{last_spam_rate: 9566\.7};
		is $s->getline => "spam_bytes: 3345150\r\n";
		is $s->getline => "spam_messages: 490\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		$ENV{ PERL5LIB } = join ':', @INC;
		exec qq($^X $bin -b$db -f -l$port --log-level=error -p$pid -w1 spamd x:$log);
	},
);

done_testing;

END {
	-f $_ and unlink $_ for grep { defined } $db,$log,$pid;
}

