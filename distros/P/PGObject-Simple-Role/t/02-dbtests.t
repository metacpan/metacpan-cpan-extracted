package test;

use Moo;
with 'PGObject::Simple::Role';

has id => (is => 'ro');
has foo => (is => 'ro');
has bar => (is => 'ro');
has baz => (is => 'ro');
has id2 => (is => 'lazy');

sub _build_id2 {
    return 10;
}

sub _get_dbh {
    return $main::dbh;
}


package test2;

use Moo;
with 'PGObject::Simple::Role';

has id => (is => 'ro');
has foo => (is => 'ro');
has bar => (is => 'ro');
has baz => (is => 'ro');


sub _get_dbh {
    return $main::dbh;
}

sub _get_prefix {
     return 'foo';
};


package main;
use Test::More;
use Test::Exception;
use DBI;
use PGObject::Simple;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
# Initial setup
my $dbh1 = DBI->connect('dbi:Pg:', 'postgres');

plan skip_all => 'Needs superuser connection for this test script' unless $dbh1;



$dbh1->do('CREATE DATABASE pgobject_test_db');

our $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres');
plan skip_all => 'No db connection' unless $dbh;

plan tests => 17;

$dbh->do('
   CREATE FUNCTION public.foobar (in_foo text, in_bar text, in_baz int, in_id int)
      RETURNS int language sql as $$
          SELECT char_length($1) + char_length($2) + $3 * $4;
      $$;
') ;
$dbh->do('CREATE SCHEMA TEST');
$dbh->do('
   CREATE FUNCTION test.foobar (in_foo text, in_bar text, in_baz int, in_id int)
      RETURNS int language sql as $$
          SELECT 2*(char_length($1) + char_length($2) + $3 * $4);
      $$;
') ;
$dbh->do('
   CREATE FUNCTION public.lazy_foobar (in_foo text, in_bar text, in_baz int, in_id2 int)
      RETURNS int language sql as $$
          SELECT char_length($1) + char_length($2) + $3 * $4;
      $$;
') ;

my ($result) = test->call_dbmethod(
              funcname => 'foobar', 
                  args => {id => 3, foo => 'test1', bar => 'test2', baz => 33},
);
is($result->{foobar}, 109, 'Correct Result, direct package call to call_dbmethod');
my $obj = test->new(id => 3, foo => 'test1', bar => 'test2', baz => 33);

($result) = $obj->call_dbmethod(funcname => 'foobar');
is($result->{foobar}, 109, 'Correct Result, no argument overrides');
$result = $obj->call_dbmethod(funcname => 'lazy_foobar');
is($result->{lazy_foobar}, 340, 'Correct handling of lazy attributes');
($result) = $obj->call_procedure(funcname => 'foobar',
                                     args => ['test1', 'testing', '3', '33']);
is($result->{foobar}, 111, 'Correct result, call_procedure');
($result) = $obj->call_procedure(funcname => 'foobar',
                               funcschema => 'test',
                                     args => ['test1', 'testing', '3', '33']);
is($result->{foobar}, 222, 'Correct result, call_procedure');
($result) = test->call_procedure(funcname => 'foobar',
                                     args => ['test1', 'testing', '3', '33']);
is($result->{foobar}, 111, 'Correct result, direct package call to call_procedure');

$result = $obj->call_dbmethod(funcname => 'foobar');
is(ref $result, ref {}, 'Correct result type, scalar return, no arg overrides');
is($result->{foobar}, 109, 'Correct Result, no argument overrides, scalar return');
$result = test->call_procedure(funcname => 'foobar',
                                     args => ['test1', 'testing', '3', '33']);
is($result->{foobar}, 111, 'Correct result, direct package call to call_procedure, scalar return');



($result) = $obj->call_dbmethod(funcname => 'foobar', args=> {baz => 1});
is($result->{foobar}, 13, 'Correct result, argument overrides');
throws_ok{$obj->call_dbmethod(funcname => 'foobar', dbh => $dbh1)} qr/No such function/, 'No such function thrown using wrong db';

$obj = test2->new(id => 3, foo => 'test1', bar => 'test2', baz => 33);

($result) = $obj->call_dbmethod(funcname => 'bar');

is($result->{foobar}, 109, 'Correct Result, no argument overrides');
($result) = $obj->call_procedure(funcname => 'bar',
                                     args => ['test1', 'testing', '3', '33']);
is($result->{foobar}, 111, 'Correct result, call_procedure');

($result) = $obj->call_dbmethod(funcname => 'bar', args=> {baz => 1});
is($result->{foobar}, 13, 'Correct result, argument overrides');

$obj->{_funcschema} = 'test';
($result) = $obj->call_procedure(funcname => 'bar',
                                     args => ['test1', 'testing', '3', '33']);

is($result->{foobar}, 222, 'Correct result, call_procedure, set schema');

($result) = $obj->call_dbmethod(funcname => 'bar', args=> {baz => 1});
is($result->{foobar}, 26, 'Correct result, argument overrides');

throws_ok{$obj->call_dbmethod(funcname => 'bar', dbh => $dbh1)} qr/No such function/, 'No such function thrown using wrong db';

# Teardown connections
$dbh->disconnect;
$dbh1->do('DROP DATABASE pgobject_test_db');
$dbh1->disconnect;
