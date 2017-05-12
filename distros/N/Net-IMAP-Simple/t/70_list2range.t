BEGIN { unless( $ENV{I_PROMISE_TO_TEST_SINGLE_THREADED} ) { print "1..1\nok 1\n"; exit 0; } }

use strict;
use warnings;

use Test;

use Net::IMAP::Simple;

plan tests => 2;

my @a = sort { rand()<=>rand() } (1 .. 50, 90 .. 99, 1000 .. 1010, 3..10);
ok( Net::IMAP::Simple->list2range(@a), my $result = "1:50,90:99,1000:1010" );

my %h;
my @b = sort { $a<=>$b } grep {!$h{$_}++} @a;
my @c = Net::IMAP::Simple->range2list($result);

ok( "@c", "@b" );
