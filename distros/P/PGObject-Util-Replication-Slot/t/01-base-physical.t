use Test::More;

use PGObject::Util::Replication::Slot;
use DBI;
use strict;
use warnings;
use Data::Dumper;
#use Carp::Always;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
plan tests => 21;

my $dbh = DBI->connect('dbi:Pg:dbname=postgres'); # no db-specific writes here

my @names = qw(pgobject_test_1 pg_object_test_2 test_pg_object1 test_pg_object2);

#create

my %slots = map { $_ => PGObject::Util::Replication::Slot->create($dbh, $_) } 
                @names;

is($_, $slots{$_}->slot_name, "Correct name for slot $_") for @names;
for my $name (@names) {
    ok((not defined $slots{$name}->current_lag_bytes), 
   "Undefined lag after creation for $name");
}

#all

is(4, (scalar PGObject::Util::Replication::Slot->all($dbh)), '4 slots total');
is(2, (scalar PGObject::Util::Replication::Slot->all($dbh, 'pg')), 
    '2 slots total starting with pg');
is(1, (scalar PGObject::Util::Replication::Slot->all($dbh, 'pgobject')), 
    '1 slot starting with pgobject');
is(2, (scalar PGObject::Util::Replication::Slot->all($dbh, 'test')), 
    '2 slot starting with test');

is (0, (scalar PGObject::Util::Replication::Slot->all($dbh, 'gredfgergwasfdgadf')),
     '0 slots found on long nonsense name');

#get

my $slot;
ok($slot = PGObject::Util::Replication::Slot->get($dbh, 'test_pg_object1'),
   'found the slot requested');
ok(not (PGObject::Util::Replication::Slot->get($dbh, 'test_pg_object_123')),
   'returned false when slot does not exist');

is('test_pg_object1', $slot->slot_name, 'Correct slot name after get');
is('physical', $slot->slot_type, 'Default is physical slot');

#delete

ok(PGObject::Util::Replication::Slot->delete($dbh, $_),
   "Success on delete of slot $_") for @names;

