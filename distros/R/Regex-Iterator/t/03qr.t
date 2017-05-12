#!perl -w

use strict;
use Test::More tests => 6;


my $string = "matched foo bar.com match";

use_ok('Regex::Iterator');


my $re = qr/MATCH[^\s]*/i;

my $it;
ok($it = Regex::Iterator->new($re, $string), "create new");

my @matches = qw(matched match);
while (my $match = $it->match()) {
	my $target = shift @matches;
	is($match, $target, "matched $target");
	ok($it->replace('matching'),"do replace") if $match =~ /ed$/;
}

my $replaced = "matching foo bar.com match";

is ($it->result, $replaced, "replaced properly");



