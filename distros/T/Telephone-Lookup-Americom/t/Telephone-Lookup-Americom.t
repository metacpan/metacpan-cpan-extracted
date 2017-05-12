# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Telephone-Lookup-Americom.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Telephone::Lookup::Americom') };


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $am = Telephone::Lookup::Americom->new();
my @res = $am->lookup('212-555');
ok(@res == 2, 'Lookup succeeded');

#use Data::Dumper; print Dumper @res;

for my $rec (@res) {
	if ($rec->{_type} eq 'AREA_CODE') {
		is($rec->{area_code}, '+1-212', 'Area Code');
		is($rec->{location}, 'New York, US (Manhattan Island)', 'Area Code Location');
	}
	elsif ($rec->{_type} eq 'EXCHANGE_CODE') {
		is($rec->{exchange_location},  'DIRECTORY ASSISTANCE', 'Exchange Location');
		is($rec->{exchange_owner}   , 'MULTIPLE OCN LISTING', 'Exchange Owner');
	}
}

