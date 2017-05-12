# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use Test;
BEGIN { plan tests => 11 };
use Perl6::Binding;
ok(1);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

##
## This file tests hashes and hash slices.
##

my %hash = (
	'one' => 1,
	'two' => 2,
	'three' => 3,
	'four' => 4,
	'five' => 5,
	'six' => 6,
	'seven' => 7,
);

sub testsub {
	my %hash := *@_;
	
	ok($hash{'one'} == 1);
	ok($hash{'five'} == 5);
	my ($one, undef, $three) := *%hash;
	ok($one == 1);
	ok($three == 3);
	$three = 33;
	ok($hash{'three'} == 33);
	my ($four, $five, $seven) := @hash{
		qw/four five seven/
	};
	ok($four == 4);
	ok($five == 5);
	ok($seven == 7);
	$seven = 77;
	ok($hash{'seven'} == 77);
	eval {
		my $eight := *%hash;
	};
	ok($@);
}

testsub(\%hash);
