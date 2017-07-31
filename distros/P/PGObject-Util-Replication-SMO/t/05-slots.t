use Test::More;

use PGObject::Util::Replication::SMO;
use DBI;
use strict;
use warnings;
use Data::Dumper;
#use Carp::Always;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 21;

my $master = PGObject::Util::Replication::SMO->new();

my @names = qw(pgobject_test_1 pg_object_test_2 test_pg_object1 test_pg_object2);

#create

my %slots = map { $_ => $master->addslot($_) } 
                @names;

is($_, $slots{$_}->slot_name, "Correct name for slot $_") for @names;
for my $name (@names) {
    ok((not defined $slots{$name}->current_lag_bytes), 
   "Undefined lag after creation for $name");
}

#all

is(4, (scalar $master->slots()), '4 slots total');
is(2, (scalar $master->slots('pg')), '2 slots total starting with pg');
is(1, (scalar $master->slots('pgobject')), '1 slot starting with pgobject');
is(2, (scalar $master->slots('test')), '2 slot starting with test');

is (0, (scalar $master->slots('gredfgergwasfdgadf')),
     '0 slots found on long nonsense name');

#get

my $slot;
ok($slot = $master->getslot('test_pg_object1'), 'found the slot requested');
ok(not ($master->getslot('test_pg_object_123')), 
'returned false when slot does not exist');

is('test_pg_object1', $slot->slot_name, 'Correct slot name after get');
is('physical', $slot->slot_type, 'Default is physical slot');

#delete

ok($master->deleteslot($_), "Success on delete of slot $_") for @names;

