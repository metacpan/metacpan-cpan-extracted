# Before "make install" is performed this script should be runnable with
# "make test". After "make install" it should work as "perl 01.t"

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
#use Test::More "no_plan";

BEGIN { use_ok('PBS::Logs') };

#########################

use PBS::Logs;

my $pl = new PBS::Logs([]);
my $obj = "PBS::Logs";

#print STDERR  ">>>>>>>>>ref = ",ref $pl,"\n";

ok(defined $pl, 'defined instance');
ok(ref $pl eq $obj, 'blessed reference');
isa_ok($pl, $obj);
can_ok($obj,qw{debug});
can_ok($pl,qw{debug datetime get filter_datetime input line current type});

is($pl->debug(), 0, "instance debug accessor read");
# set instance debug
$pl->debug(2);
is($pl->debug(), 2, "instance debug accessor set");
$pl->debug(0);

is(PBS::Logs::debug(), 0, "class debug accessor read");
#set class debug
PBS::Logs::debug(3);
is(PBS::Logs::debug(), 3, "class debug accessor set");
PBS::Logs::debug(0);

