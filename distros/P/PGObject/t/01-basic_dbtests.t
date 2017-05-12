use Test::More;
use DBI;
use PGObject;

plan skip_all => 'Not set up for db tests' unless $ENV{DB_TESTING};
# Initial setup
my $dbh1 = DBI->connect('dbi:Pg:', 'postgres') ;

plan skip_all => 'Needs superuser connection for this test script' unless $dbh1;

plan tests => 35;


$dbh1->do('CREATE DATABASE pgobject_test_db');


my $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres');
$dbh->{pg_server_prepare} = 0;

# Function to test.
$dbh->do('
   CREATE FUNCTION public.pg_object_test
          (in_test1 int, in_test2 text, in_test3 date)
   RETURNS BOOL LANGUAGE SQL AS $$ SELECT TRUE $$
');

$dbh->do('CREATE DOMAIN public.posint AS int');
$dbh->do('
   CREATE FUNCTION public.pg_object_test2
          (in_test1 posint, in_test2 text, in_test3 date)
   RETURNS BOOL LANGUAGE SQL AS $$ SELECT TRUE $$
');




# Testing function_info()
my $function_info = PGObject->function_info(
    dbh      => $dbh,
    funcname => 'pg_object_test'
);
my $function_info2 = PGObject->function_info(
    dbh        => $dbh,
    funcname   => 'pg_object_test',
    funcschema => 'public',
);
my $function_info3 = PGObject->function_info(
    dbh        => $dbh,
    funcname   => 'pg_object_test',
    funcschema => 'public',
    argtype1   => 'int4',
    argschema  => 'pg_catalog',
);


ok(defined $function_info, 'Got function info with default schema');
ok(defined $function_info2, 'Got function info with specified schema');
ok(defined $function_info3, 'Got function info with specified schema, first arg type');
is($function_info->{args}->[0]->{name}, 'in_test1', 
  'default schema, arg1 name');
is($function_info->{args}->[1]->{name}, 'in_test2', 
  'default schema, arg2 name');
is($function_info->{args}->[2]->{name}, 'in_test3', 
  'default schema, arg3 name');
is($function_info2->{args}->[0]->{name}, 'in_test1', 
  'specified schema, arg1 name');
is($function_info2->{args}->[1]->{name}, 'in_test2', 
  'specified schema, arg2 name');
is($function_info2->{args}->[2]->{name}, 'in_test3', 
  'specified schema, arg1 name');
is($function_info3->{args}->[0]->{name}, 'in_test1', 
  'specified schema and arg type, arg1 name');
is($function_info3->{args}->[1]->{name}, 'in_test2', 
  'specified schema and arg type, arg2 name');
is($function_info3->{args}->[2]->{name}, 'in_test3', 
  'specified schema and arg type, arg1 name');


is($function_info->{args}->[0]->{type}, 'integer', 
  'default schema, arg1 type');
is($function_info->{args}->[1]->{type}, 'text', 
  'default schema, arg2 type');
is($function_info->{args}->[2]->{type}, 'date', 
  'default schema, arg3 type');
is($function_info2->{args}->[0]->{type}, 'integer', 
  'specified schema, arg1 type');
is($function_info2->{args}->[1]->{type}, 'text', 
  'specified schema, arg2 type');
is($function_info2->{args}->[2]->{type}, 'date', 
  'specified schema, arg1 type');
is($function_info3->{args}->[0]->{type}, 'integer', 
  'specified schema/arg type, arg1 type');
is($function_info3->{args}->[1]->{type}, 'text', 
  'specified schema/arg type, arg2 type');
is($function_info3->{args}->[2]->{type}, 'date', 
  'specified schema/arg type, arg1 type');

is($function_info->{num_args}, 3, 'Number of args, default schema');
is($function_info2->{num_args}, 3, 'Number of args, specified schema');
is($function_info->{name}, 'pg_object_test', 'Func. Name, default schema');
is($function_info2->{name}, 'pg_object_test', 'Func name, specified schema');

# Testing call_procedure()

my ($result1) = PGObject->call_procedure(
   funcname   => 'pg_object_test',
   args       => [1, 'test', '2001-01-01'],
   dbh        => $dbh,
);
my ($result2) = PGObject->call_procedure(
   funcname   => 'pg_object_test',
   funcschema => 'public',
   args       => [1, 'test', '2001-01-01'],
   dbh        => $dbh,
);
my ($result3) = PGObject->call_procedure(
   funcname      => 'pg_object_test',
   args          => [1, 'test', '2001-01-01'],
   dbh           => $dbh,
   running_funcs => [{agg => 'count(*)', alias => 'lines'}]
);
my ($result4) = PGObject->call_procedure(
   funcname   => 'test',
   funcprefix => 'pg_object_',
   args       => [1, 'test', '2001-01-01'],
   dbh        => $dbh,
);

ok(defined $result1, 'Basic call returned results, default schema');
ok(defined $result2, 'Basic call returned results, specified schema');
ok(defined $result3, 'Call returned results, default schema, windowed aggs');
ok(defined $result4, 'Prefixed call returned results, default schema');
ok($result1->{pg_object_test}, 'Correct value returned for proc result1');
ok($result2->{pg_object_test}, 'Correct value returned for proc result2');
ok($result3->{pg_object_test}, 'Correct value returned for proc result3');
ok($result4->{pg_object_test}, 'Correct value returned for proc result4');
is($result3->{lines}, 1, 'Correct running agg returned for proc result3');

ok(!$@, 'No eval failures bleeding up') or diag ("eval error bled up: $@");
$dbh->disconnect;
$dbh1->do('DROP DATABASE pgobject_test_db');
$dbh1->disconnect;
