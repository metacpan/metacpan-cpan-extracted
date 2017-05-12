package comptest;
use base qw(PGObject::Composite PGObject::Type::Composite);
use DBI;

sub _get_dbh {$main::dbh}
sub _get_typename { 'footype' }
sub _get_schema { 'public' }

sub new {
    my $pkg = shift;
    my %props = @_;
    bless \%props, $pkg;
}

package main;
use Test::More;
my %hash = (
   foo => 'foo',
   bar => 'baz',
   baz => '2',
   id  => '33',
);

my $ref;

plan skip_all => 'Not set up for db tests' unless $ENV{DB_TESTING};
plan tests => 11;
my $dbh1 = DBI->connect('dbi:Pg:dbname=postgres', 'postgres');
$dbh1->do('CREATE DATABASE pgobject_test_db') if $dbh1;


our $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres');
$dbh->do('CREATE TYPE footype AS (foo text, bar text, baz int, id int)');
$dbh->do('
   CREATE FUNCTION public.foobar (in_self footype)
      RETURNS int language sql as $$
          SELECT char_length($1.foo) + char_length($1.bar) + $1.baz * $1.id;
      $$;
') if $dbh;
$dbh->do('
   CREATE FUNCTION public.multifoo (in_self footype, in_factor int)
      RETURNS int language sql as $$
          SELECT foobar($1) * $2;
      $$;
') if $dbh;

my $answer = 72;

my $obj;

ok ($obj = comptest->new(%hash), 'created new object');
is ($obj->_get_dbh, $dbh, 'dbh correctly set');
ok (comptest->initialize(dbh => $dbh), 'initialized object');
ok($ref = $obj->call_dbmethod(funcname => 'foobar'), 'Called simple method successfully');

is($ref->{foobar}, $answer, 'Got correct answer from foobar');

ok($ref = $obj->call_procedure(funcname => 'foobar', args => [$obj]), 
   'called same function using call_procedure');

is($ref->{foobar}, $answer, 'Got correct answer from foobar using call_procedure');

ok($ref = $obj->call_procedure(funcname => 'multifoo', args => [$obj, 4]), 
   'called multifoo function using call_procedure');

is($ref->{multifoo}, $answer * 4, 'Got correct answer from multifoo using call_procedure');

ok($ref = $obj->call_dbmethod(funcname => 'multifoo', args => { factor => 4 }),
   'called multifoo using call_dbmethod');

is($ref->{multifoo}, $answer * 4, 'got correct answer from multifoo using calldbmethod');

$dbh->disconnect if $dbh;
$dbh1->do('DROP DATABASE pgobject_test_db') if $dbh1;
$dbh1->disconnect if $dbh1;

