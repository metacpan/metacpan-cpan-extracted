use PGObject::Simple;
use Test::More tests => 5;
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
is($dbh, $obj->dbh, "database handle cross check");

my $obj2 = PGObject::Simple->new(%hash);
is($obj2->dbh, undef, 'No db handle for second object');
$obj2->associate($obj);
is($dbh, $obj2->dbh, "database handle cross check after association");

