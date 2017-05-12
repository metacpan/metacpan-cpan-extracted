use Test::More tests => 14;
use DBI;
use PGObject;


is(PGObject->new_registry('test1'), 1, 'New registry 1 created');
is(PGObject->new_registry('blank'), 1, 'New registry blank created');
is(PGObject->new_registry('test2'), 1, 'New registry 2 created');
is(PGObject->register_type(pg_type => 'int4', perl_class => 'test1'), 1,
       "Basic type registration");
is(PGObject->register_type(
        pg_type => 'int4', perl_class => 'test2', registry => 'test1'), 1,
       "Basic type registration");

SKIP: {
    skip 'No database connection', 9 unless $ENV{DB_TESTING};

    # Initial db setup

    my $dbh1 = DBI->connect('dbi:Pg:', 'postgres') ;


    $dbh1->do('CREATE DATABASE pgobject_test_db') if $dbh1;




    my $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres') if $dbh1;




    $dbh->{pg_server_prepare} = 0 if $dbh;


    # Functions to test.


    $dbh->do('
    CREATE OR REPLACE FUNCTION test_serialization(int) returns int language sql as $$
    SELECT $1;
    $$') if $dbh;

    $dbh->do('
    CREATE OR REPLACE FUNCTION test_int() returns int language sql as $$
    SELECT 1000;
    $$') if $dbh;

    $dbh->do('
    CREATE OR REPLACE FUNCTION test_ints() returns int[] language sql as $$
    SELECT array[1000::int, 100, 10];
    $$') if $dbh;
    my ($result) = PGObject->call_procedure(
        funcname   => 'test_int',
        args       => [],
        dbh        => $dbh,
    );

    is($result->{test_int}, 4, 'Correct handling of override, default registry');

    ($result) = PGObject->call_procedure(
        funcname   => 'test_int',
        args       => [],
        dbh        => $dbh,
        registry   => 'test1',
    );


    is($result->{test_int}, 8, 'Correct handling of override, named registry');

    ok(($result) = PGObject->call_procedure(
        funcname   => 'test_ints',
        args       => [],
        dbh        => $dbh,
    ));

    for (0 .. 2) {
        is $result->{test_ints}->[$_], 4, "Array element $_ handled by registered type";
    }

    ($result) = PGObject->call_procedure(
        funcname   => 'test_int',
        args       => [],
        dbh        => $dbh,
        registry   => 'test2',
    );

   
    is($result->{test_int}, 1000, 
          'Correct handling of override, named registry with no override');

    my $test = bless {}, 'test1';
    ok(($result) = PGObject->call_procedure(
        funcname => 'test_serialization',
             dbh => $dbh,
            args => [$test],
        registry => 'blank',
    ), 'called test_serialization correctly');
    is($result->{test_serialization}, 8, 'serialized to db correctly');
           
    $dbh->disconnect if $dbh;
    $dbh1->do('DROP DATABASE pgobject_test_db') if $dbh1;
    $dbh1->disconnect if $dbh1;
}


package test1;

sub from_db {
    return 4;
}

sub to_db {
    return 8
}

package test2;

sub from_db {
    return 8
}
