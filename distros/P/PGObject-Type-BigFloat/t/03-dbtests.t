use Test::More;
use DBI;
use PGObject;
use PGObject::Type::BigFloat;
PGObject::Type::BigFloat->register();

my $functions = {
     float4 => '
               create or replace function test__float4() returns float4
               language sql as
               $$SELECT 1.345::float4;$$',
     float8 => '
               create or replace function test__float8() 
               returns float
               language sql as
               $$SELECT 1.345::double precision;$$',
     numeric => '
               create or replace function test__numeric() returns numeric
               language sql as
               $$SELECT 1.345::numeric;$$',
     round_trip => '
               create or replace function test__roundtrip(numeric) returns numeric
               language sql as
               $$SELECT $1;$$',
     null => '
               CREATE OR REPLACE FUNCTION test__null() RETURNS numeric
               LANGUAGE SQL AS $$ SELECT null::numeric; $$ ',
               
};

plan skip_all => 'Not set up for dbtests' unless $ENV{DB_TESTING};

# DB Setup

my $predbh = DBI->connect('dbi:Pg:', 'postgres');
plan skip_all => "Could not get superuser access to db. skipping" unless $predbh;

$predbh->do('CREATE DATABASE test_pgobject_type_bigfloat');
my $dbh = DBI->connect('dbi:Pg:dbname=test_pgobject_type_bigfloat');

for my $fnc (keys %$functions){
    $dbh->do($functions->{$fnc});
}

# Planning

if ($dbh) {
   plan tests => 12;
} else {
   plan skipall => "No database connection, or connection failed";
}

# Test cases

for my $type (qw(float4 float8 numeric)){
    my ($ref) = PGObject->call_procedure(
           funcname   => $type,
           funcprefix => 'test__',
           args       => [],
           dbh        => $dbh,
    );
    my ($val) = values %$ref;
    ok(eval {$val->isa('Math::BigFloat')}, "Type $type returns BigFloat object");
    ok(eval {$val->isa('PGObject::Type::BigFloat')}, 
                     "Type $type returns PGObject::Type::BigFloat object");
}

my ($ref) = PGObject->call_procedure(
           funcname   => 'null',
           funcprefix => 'test__',
           args       => [],
           dbh        => $dbh,
);
my ($val) = values %$ref;
ok(eval {$val->isa('Math::BigFloat')}, "Type null returns BigFloat object");
ok(eval {$val->isa('PGObject::Type::BigFloat')}, 
                     "Type null returns PGObject::Type::BigFloat object");
ok(! defined $val->to_db, 'null returns undef to db');

$val = PGObject::Type::BigFloat->new(1.222);

($ref) = PGObject->call_procedure(
           funcname   => 'roundtrip',
           funcprefix => 'test__',
           args       => [$val],
           dbh        => $dbh,
);
($val) = values %$ref;
ok(eval {$val->isa('Math::BigFloat')}, "Roundtrip returns BigFloat object");
ok(eval {$val->isa('PGObject::Type::BigFloat')}, 
                 "Roundtrip returns PGObject::Type::BigFloat object");

is(eval {$val->to_db}, '1.222', 'Round Trip returns same value sent');


# DB Cleanup

$dbh->disconnect;
$predbh->do('DROP DATABASE test_pgobject_type_bigfloat');

