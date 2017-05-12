# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use Test;
BEGIN { plan tests => 10 };
use Perl6::Binding;
ok(1);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
my @array = qw(
	one two three four five six seven
);

##
## This module tests aliases to arrays and array slices.
##
sub testsub {
	my @array := *@_;
	ok($array[0] eq 'one');
	ok($array[1] eq 'two');
	my ($one, undef, $three) := *@array;
	ok($one eq 'one');
	ok($three eq 'three');
	$one = 'uno';
	ok($array[0] eq 'uno');
	my ($four, $five, $seven) := @array[3, 4, 6];
	ok($four eq 'four');
	ok($five eq 'five');
	ok($seven eq 'seven');
	$four = 'quattro';
	ok($array[3] eq 'quattro');
}

testsub(\@array);

