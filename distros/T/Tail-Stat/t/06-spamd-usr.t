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
		is $s->getline => "clean:alexeeva: 3\r\n";
		is $s->getline => "clean:alimova: 1\r\n";
		is $s->getline => "clean:antonina: 2\r\n";
		is $s->getline => "clean:chief: 1\r\n";
		is $s->getline => "clean:genger: 1\r\n";
		is $s->getline => "clean:lilly: 2\r\n";
		is $s->getline => "clean:pushkina: 2\r\n";
		is $s->getline => "clean:ryabova: 3\r\n";
		is $s->getline => "clean:sale: 2\r\n";
		is $s->getline => "clean:sale-dinamik: 1\r\n";
		is $s->getline => "clean:sergey: 1\r\n";
		is $s->getline => "clean:shurik: 1\r\n";
		is $s->getline => "clean:stavrakova: 4\r\n";
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
		is $s->getline => "spam:alexeeva: 8\r\n";
		is $s->getline => "spam:alimova: 7\r\n";
		is $s->getline => "spam:buh: 8\r\n";
		is $s->getline => "spam:chief: 9\r\n";
		is $s->getline => "spam:edit: 8\r\n";
		is $s->getline => "spam:elya: 8\r\n";
		is $s->getline => "spam:galina: 10\r\n";
		is $s->getline => "spam:genger: 5\r\n";
		is $s->getline => "spam:goncharova: 7\r\n";
		is $s->getline => "spam:kostrikina: 6\r\n";
		is $s->getline => "spam:kovaleva: 15\r\n";
		is $s->getline => "spam:kuznetzova: 8\r\n";
		is $s->getline => "spam:li: 7\r\n";
		is $s->getline => "spam:lilly: 55\r\n";
		is $s->getline => "spam:m.nina: 10\r\n";
		is $s->getline => "spam:manager-shop: 15\r\n";
		is $s->getline => "spam:marina: 11\r\n";
		is $s->getline => "spam:michael: 7\r\n";
		is $s->getline => "spam:monakhova: 6\r\n";
		is $s->getline => "spam:natasha: 17\r\n";
		is $s->getline => "spam:okosta: 7\r\n";
		is $s->getline => "spam:oksana: 7\r\n";
		is $s->getline => "spam:order-shop: 8\r\n";
		is $s->getline => "spam:pal: 8\r\n";
		is $s->getline => "spam:popova: 5\r\n";
		is $s->getline => "spam:pospelova: 9\r\n";
		is $s->getline => "spam:pushkina: 10\r\n";
		is $s->getline => "spam:ryabova: 37\r\n";
		is $s->getline => "spam:sale: 30\r\n";
		is $s->getline => "spam:sale-dinamik: 7\r\n";
		is $s->getline => "spam:samujlova: 9\r\n";
		is $s->getline => "spam:sasha: 13\r\n";
		is $s->getline => "spam:secretary: 6\r\n";
		is $s->getline => "spam:serge_ali: 8\r\n";
		is $s->getline => "spam:sergey: 17\r\n";
		is $s->getline => "spam:shurik: 28\r\n";
		is $s->getline => "spam:spb: 6\r\n";
		is $s->getline => "spam:stavrakova: 2\r\n";
		is $s->getline => "spam:support: 5\r\n";
		is $s->getline => "spam:svetlana: 6\r\n";
		is $s->getline => "spam:vovka: 8\r\n";
		is $s->getline => "spam:zoya: 8\r\n";
		is $s->getline => "spam:zudenkova: 19\r\n";
		is $s->getline => "spam_bytes: 3345150\r\n";
		is $s->getline => "spam_messages: 490\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		$ENV{ PERL5LIB } = join ':', @INC;
		exec qq($^X $bin -b$db -f -l$port --log-level=error -o usr -p$pid -w1 spamd x:$log);
	},
);

done_testing;

END {
	-f $_ and unlink $_ for grep { defined } $db,$log,$pid;
}

