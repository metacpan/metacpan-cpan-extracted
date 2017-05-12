# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl STANAG.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

BEGIN { use_ok('STANAG', qw(Get_Vehicle_Name Get_Vehicle_Subtype)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $hashref = STANAG::Vehicle_ID();

$hashref->{Vehicle_Type} = 22;
$hashref->{Vehicle_Subtype} = 101;

my $flat = STANAG::Encode_Vehicle_ID($hashref);
my $hashref2 = STANAG::Decode_Vehicle_ID($flat);

my $hashref3 = STANAG::Vehicle_ID();

is_deeply($hashref2, $hashref3);

is(Get_Vehicle_Name($hashref2->{Vehicle_Type}), "Luna", "Checked a name");
is(Get_Vehicle_Subtype($hashref2->{Vehicle_Subtype}), "Manta", "Checked another name");

