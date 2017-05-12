use Test::More;
use DBI;
use PGObject;
use PGObject::Type::DateTime;
PGObject::Type::DateTime->register();

my $functions = {
     time => q|
               create or replace function test__time() returns time
               language sql as
               $$SELECT '11:11:11.00'::time;$$|,
     date => q|
               create or replace function test__date() returns date
               language sql as
               $$SELECT '2012-11-01'::date;$$|,
     timestamp => q|
               create or replace function test__timestamp() returns timestamp
               language sql as
               $$SELECT '2012-01-01 11:11:11.00'::timestamp;$$|,
     timestamptz => q|
               create or replace function test__timestamptz() 
               returns timestamptz
               language sql as
               $$SELECT '2012-01-01 11:11:11.00-8'::timestamptz;$$|,
     round_trip => '
               create or replace function test__roundtrip(date) returns date
               language sql as
               $$SELECT $1;$$',
               
};

plan skip_all => 'Not set up for dbtests' unless $ENV{DB_TESTING};

# DB Setup

my $predbh = DBI->connect('dbi:Pg:', 'postgres');
plan skip_all => "Could not get superuser access to db. skipping" unless $predbh;

$predbh->do('CREATE DATABASE test_pgobject_type_datetime');
my $dbh = DBI->connect('dbi:Pg:dbname=test_pgobject_type_datetime');

for my $fnc (keys %$functions){
    $dbh->do($functions->{$fnc});
}

# Planning

if ($dbh) {
   plan tests => 11;
} else {
   plan skipall => "No database connection, or connection failed";
}

# Test cases

for my $type (qw(date time timestamp timestamptz)){
    my ($ref) = PGObject->call_procedure(
           funcname   => $type,
           funcprefix => 'test__',
           args       => [],
           dbh        => $dbh,
    );
    my ($val) = values %$ref;
    ok(eval {$val->isa('DateTime')}, "Type $type returns DateTime object");
    ok(eval {$val->isa('PGObject::Type::DateTime')}, 
                     "Type $type returns PGObject::Type::DateTime object");
}

my $orig = '2012-01-01';

my $val = PGObject::Type::DateTime->from_db($orig);
my ($ref) = PGObject->call_procedure(
           funcname   => 'roundtrip',
           funcprefix => 'test__',
           args       => [$val],
           dbh        => $dbh,
);
($val) = values %$ref;
ok(eval {$val->isa('DateTime')}, "Roundtrip returns DateTime object");
ok(eval {$val->isa('PGObject::Type::DateTime')}, 
                 "Roundtrip returns PGObject::Type::DateTime object");

is(eval {$val->to_db}, $orig, 'Round Trip returns same value sent');


# DB Cleanup

$dbh->disconnect;
$predbh->do('DROP DATABASE test_pgobject_type_datetime');

