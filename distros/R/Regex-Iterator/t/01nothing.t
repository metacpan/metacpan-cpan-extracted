#!perl -w

use strict;
use Test::More tests => 7;


my $string = "no match";

use_ok('Regex::Iterator');

my $it;
ok($it = Regex::Iterator->new('foo', $string), "create new");

my $count = 1;
while (my $match = $it->match()) {
	
	$count = 0;
	last;
}
is($count,1, "Checking to see if it terminates");



ok($it = Regex::Iterator->new('foo', $string), "create new again");


$string =~ m!(url)!; # make sure that we're not fooled by matches other than our own

$count = 1;
while (my $match = $it->match()) {

    $count = 0;
    last;
}
is($count,1, "Checking to see if it terminates");

is($count,1, "Checking to see if it terminates again");

is ($it->result, $string, "replaced properly");



