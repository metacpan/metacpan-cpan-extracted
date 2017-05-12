# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Pipe-Between-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 21;
BEGIN { use_ok('Pipe::Between::Object') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $pbo = Pipe::Between::Object->new();

isa_ok($pbo, 'Pipe::Between::Object');

can_ok($pbo, qw/count pull push/);

is($pbo->count, 0, "Check count function");
my ($val, $res) = $pbo->pull();

is($val, undef, "Check pull function.");
is($res, 1, "Check pull function.");

$pbo->push(1);
($val, $res) = $pbo->pull();

is($val, 1, "Check push function.");
is($res, 0, "Check push function.");

for(my $i = 0; $i < 5; $i++) {
	$pbo->push($i);
}

is($pbo->count, 5, "Check count function");

for(my $i = 0; $i < 5; $i++) {
	($val, $res) = $pbo->pull();
	is($val, $i, "Check push function.");
	is($res, 0, "Check push function.");
}
($val, $res) = $pbo->pull();
is($val, undef, "Check push function.");
is($res, 1, "Check push function.");
