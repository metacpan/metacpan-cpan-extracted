package dbtest;
use parent 'PGObject::Simple';
sub dbh {
    my ($self) = @_;
    return $self->SUPER::dbh(@_) if ref $self;
    return $main::dbh;
}

sub func_prefix {
    return '';
}

sub func_schema {
    return 'public';
}

package main;

use PGObject::Simple;
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
plan tests => 11;
my $dbh1 = DBI->connect('dbi:Pg:dbname=postgres', 'postgres');
$dbh1->do('CREATE DATABASE pgobject_test_db') if $dbh1;


our $dbh = DBI->connect('dbi:Pg:dbname=pgobject_test_db', 'postgres');
$dbh->do('
   CREATE FUNCTION public.foobar (in_foo text, in_bar text, in_baz int, in_id int)
      RETURNS int language sql as $$
          SELECT char_length($1) + char_length($2) + $3 * $4;
      $$;
') if $dbh;

$dbh->do('CREATE SCHEMA test;');

$dbh->do('
   CREATE FUNCTION test.foobar (in_foo text, in_bar text, in_baz int, in_id int)
      RETURNS int language sql as $$
          SELECT 2 * (char_length($1) + char_length($2) + $3 * $4);
      $$;
') if $dbh;

my $answer = 72;

SKIP: {
   skip 'No database connection', 8 unless $dbh;
   my $obj = PGObject::Simple->new(%hash);
   $obj->set_dbh($dbh);
   my ($ref) = $obj->call_procedure(
      funcname => 'foobar',
      args => ['text', 'text2', '5', '30']
   );
   is ($ref->{foobar}, 159, 'Correct value returned, call_procedure') or diag Dumper($ref);

   ($ref) = PGObject::Simple->call_procedure(
      dbh => $dbh,
      funcname => 'foobar',
      args => ['text', 'text2', '5', '30']
   );
   is ($ref->{foobar}, 159, 'Correct value returned, call_procedure, package invocation') or diag Dumper($ref);

   ($ref) = dbtest->call_procedure(funcname => 'foobar', 
	   args => ['text', 'text2', '5', '30']
   );
   is ($ref->{foobar}, 159, 'Correct value returned, package invocation with factories') or diag Dumper($ref);


   ($ref) = $obj->call_procedure(
      funcname => 'foobar',
      funcschema => 'public',
      args => ['text1', 'text2', '5', '30']
   );

   is ($ref->{foobar}, 160, 'Correct value returned, call_procedure w/schema') or diag Dumper($ref);

   ($ref) = $obj->call_dbmethod(
      funcname => 'foobar'
   );

   is ($ref->{foobar}, $answer, 'Correct value returned, call_dbmethod') or diag Dumper($ref);
   ($ref) = PGObject::Simple->call_dbmethod(
      funcname => 'foobar',
          args => \%hash,
           dbh => $dbh,
   );
   is ($ref->{foobar}, $answer, 'Correct value returned, call_dbmethodi with hash and no ref') or diag Dumper($ref);
       
   ($ref) = dbtest->call_dbmethod(funcname => 'foobar', 
	   args => \%hash
   );
   is ($ref->{foobar}, $answer, 'Correct value returned, package invocation with factories and dbmethod') or diag Dumper($ref);


   ($ref) = $obj->call_dbmethod(
      funcname => 'foobar',
      args     => {id => 4}
   );

   is ($ref->{foobar}, 14, 'Correct value returned, call_dbmethod w/args') or diag Dumper($ref);
   $obj->_set_funcprefix('foo');
   ($ref) = ($ref) = $obj->call_dbmethod(
      funcname => 'bar',
      args     => {id => 4}
   );
   is ($ref->{foobar}, 14, 'Correct value returned, call_dbmethod w/args/prefix') or diag Dumper($ref);
   ($ref) = ($ref) = $obj->call_dbmethod(
      funcname => 'oobar',
      args     => {id => 4},
    funcprefix => 'f'
   );
   is ($ref->{foobar}, 14, 'Correct value returned, call_dbmethod w/exp. pre.') or diag Dumper($ref);

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
