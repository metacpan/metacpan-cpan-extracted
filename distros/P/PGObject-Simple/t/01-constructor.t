use PGObject::Simple;
use Test::More tests => 3;
use DBI;

my %hash = (
   foo => 'foo',
   bar => 'baz',
   baz => '2',
   id  => '33',
);

my $dbh = 'test_dbh_fake_value';

my $obj = PGObject::Simple->new(%hash);

ok($obj->isa('PGObject::Simple'), 'Object successfully created');

is($obj->set_dbh($dbh), $dbh, 'Set database handle successfully');
is($dbh, $obj->{_DBH}, "database handle cross check");

