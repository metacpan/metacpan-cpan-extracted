package dbtest;
use parent 'PGObject::Composite';

sub _get_typename { 'foo' };
sub _get_typeschema { 'public' };
sub dbh {
    my ($self) = @_;
    return $self->SUPER::dbh(@_) if ref $self;
    return $main::dbh;
}

sub default_dbh {
    return $main::dbh;
}

sub func_prefix {
    return '';
}

sub func_schema {
    return 'public';
}

package main;

use PGObject::Composite;
use Test::More;
use DBI;
use Data::Dumper;

my %hash = (
   foo => 'foo',
   bar => 'baz',
   baz => '2',
   id  => '33',
);

plan skip_all => 'Not set up for db tests' unless $ENV{DB_TESTING};
plan tests => 10;
my $dbh1 = DBI->connect('dbi:Pg:dbname=postgres', 'postgres');
$dbh1->do('CREATE DATABASE pgobject_test_db') if $dbh1;


our $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres');
$dbh->do('
   CREATE TYPE public.foo as ( foo text, bar text, baz int, id int )
   ') if $dbh;

$dbh->do('
   CREATE FUNCTION public.foobar(in_self foo)
      RETURNS int language sql as $$
          SELECT char_length($1.foo) + char_length($1.bar) + $1.baz * $1.id;
      $$;
') if $dbh;

$dbh->do('CREATE SCHEMA test;') if $dbh;

$dbh->do('
   CREATE FUNCTION test.foobar (in_self public.foo)
      RETURNS int language sql as $$
          SELECT 2 * (char_length($1.foo) + char_length($1.bar) + $1.baz * $1.id);
      $$;
') if $dbh;

my $answer = 72;

SKIP: {
   skip 'No database connection', 7 unless $dbh;
   my @cols = dbtest->initialize(dbh => $dbh);
   ok(scalar @cols, 'Have 1 or more columns');
   my $obj = dbtest->new(%hash);
   $obj->set_dbh($dbh);
   ok($obj->can('to_db'), 'can serialize self to db');
   is($obj->dbh, $dbh, 'DBH set');
   is($obj->_get_dbh, $dbh, 'DBH set, internal accessor');
   is_deeply({$obj->_build_args()}, {dbh => $dbh, funcschema => 'public', funcprefix => '', registry => 'default', typeschema => 'public', typename => 'foo'}, 'Args set, defaults');
   is_deeply({$obj->_build_args({funcschema => 'test', registry => 'foo', funcprefix => 'tttt'})}, {funcschema => 'test', registry => 'foo', funcprefix => 'tttt', typename => 'foo', typeschema => 'public', dbh => $dbh}, 'Args set, overrides');
   my ($ref) = $obj->call_procedure(
      funcname => 'foobar',
      args => [$obj]
   );
   is ($ref->{foobar}, 72, 'Correct value returned, call_procedure') or diag Dumper($ref);

   ($ref) = dbtest->call_procedure(
      dbh => $dbh,
      funcname => 'foobar',
      args => [$obj],
   );
   is ($ref->{foobar}, 72, 'Correct value returned, call_procedure, package invocation') or diag Dumper($ref);


   ($ref) = $obj->call_dbmethod(
      funcname => 'foobar'
   );

   is ($ref->{foobar}, $answer, 'Correct value returned, call_dbmethod') or diag Dumper($ref);
       

   $obj->_set_funcschema('test');
   $obj->_set_funcprefix('');
   ($ref) = $obj->call_dbmethod(
      funcname => 'foobar'
   );

   is ($ref->{foobar}, $answer * 2, 'Correct value returned, call_dbmethod') or diag Dumper($ref);
   $obh = dbtest->new();

}

$dbh->disconnect if $dbh;
$dbh1->do('DROP DATABASE pgobject_test_db') if $dbh1;
$dbh1->disconnect if $dbh1;
