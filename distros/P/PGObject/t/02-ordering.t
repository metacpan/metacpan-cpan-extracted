use Test::More;
use DBI;
use PGObject;
use strict;
use warnings;


plan skip_all => 'Not set up for db tests' unless $ENV{DB_TESTING};
# Initial setup
my $dbh1 = DBI->connect('dbi:Pg:', 'postgres');

plan skip_all => 'Needs superuser connection for this test script' unless $dbh1;

plan tests => 20;


$dbh1->do('CREATE DATABASE pgobject_test_db');


my $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres');

# Function to test:

$dbh->do(q|
   CREATE OR REPLACE FUNCTION pgobject_order_test()
   RETURNS TABLE(col1 int, col2 text, col3 int)
   language sql as
   $$
      SELECT 1, 'group1', 1
      union
      select 2, 'group2', 2
      union 
      select 3, 'group1', 2
      union
      select 4, 'group2', 1
   $$;
|);

my @resultset = PGObject->call_procedure( # no order
   funcname   => 'pgobject_order_test',
   dbh        => $dbh,
);

is(scalar @resultset, 4, 'Unordered call successful, returned 4 rows');

@resultset = PGObject->call_procedure( # ordered by col1
   funcname   => 'pgobject_order_test',
   dbh        => $dbh,
   orderby    => ['col1'],
);

for my $num (1 .. 4){
   is($resultset[$num - 1]->{col1}, $num, "simple ordering, correct result for item $num");
}


@resultset = PGObject->call_procedure( # ordered by col1
   funcname   => 'pgobject_order_test',
   dbh        => $dbh,
   orderby    => ['col1 asc'],
);

for my $num (1 .. 4){
   is($resultset[$num - 1]->{col1}, $num, "simple explicit ordering, correct result for item $num");
}

@resultset = PGObject->call_procedure( # Reverse simple order
   funcname   => 'pgobject_order_test',
   dbh        => $dbh,
   orderby    => ['col1 desc'],
);

for my $num (0 .. 3){
   is($resultset[$num]->{col1}, 4 - $num, "simple reverse ordering, correct result for item $num");
}

@resultset = PGObject->call_procedure( # Compound, complex ordering
   funcname   => 'pgobject_order_test',
   dbh        => $dbh,
   orderby    => ['col2 desc', 'col3 asc'],
);

my @expected = (4, 2, 1, 3);

for my $num (0 .. 3){
   is($resultset[$num]->{col1}, $expected[$num], "simple reverse ordering, correct result for item $num");
}



$dbh->do(q|
   CREATE OR REPLACE FUNCTION pgobject_order_test(id int)
   RETURNS TABLE(col1 int, col2 text, col3 int)
   language sql as
   $$
      SELECT 1, 'group1', 1
      union
      select 2, 'group2', 2
      union 
      select 3, 'group1', 2
      union
      select 4, 'group2', 1
   $$;
|);
    PGObject::clear_info_cache();
    eval {
        PGObject->function_info(
            funcname   => 'pgobject_order_test',
            dbh        => $dbh,
        );
        ok(0, 'Should have died') or diag 'Should have died';
    };
    {   local $_ = $@;
        is($_->{state}, '42A01', 'Errored on duplicate function');
    }
    eval {
        PGObject->function_info(
            funcname   => 'pgobject_ordering_foo',
            dbh        => $dbh
        );
        ok(0, 'Should have died') or diag 'Should have died';
    };
    {
        local $_ = $@;
        is($_->{state}, '26A01', 'Errored on duplicate function');
    }
$dbh->do(q| DROP FUNCTION pgobject_order_test(); |);
    eval {
        PGObject->call_procedure(
            funcname   => 'pgobject_order_test',
            dbh        => $dbh,
            args       => ['foo'],
        );
    };
    {
        local $_ = $@;
        is($_->{state}, '22P02', 'Got correct state back');
    }


# Teardown connections
$dbh->disconnect;
$dbh1->do('DROP DATABASE pgobject_test_db');
$dbh1->disconnect;
