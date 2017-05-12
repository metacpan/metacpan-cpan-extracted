# Before "make install" is performed this script should be runnable with
# "make test". After "make install" it should work as "perl 01.t"

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
#use Test::More "no_plan";

BEGIN { use_ok('PBS::Logs::Acct') };

#########################

use PBS::Logs::Acct;

my $pl = new PBS::Logs::Acct([]);
my $supobj = "PBS::Logs";
my $obj = $supobj."::Acct";

#print STDERR  ">>>>>>>>>ref = ",ref $pl,"\n";

ok(defined $pl, 'defined instance');
ok(ref $pl eq $obj, 'blessed reference');
isa_ok($pl, $obj);
isa_ok($pl, $supobj);
can_ok($supobj,qw{debug});
can_ok($obj,qw{debug message_hash message_hash_dump});
can_ok($pl,qw{debug datetime get filter_datetime input line current type
	message_hash message_hash_dump});

is($pl->debug(), 0, "instance debug accessor read");
# set instance debug
$pl->debug(2);
is($pl->debug(), 2, "instance debug accessor set");
$pl->debug(0);

