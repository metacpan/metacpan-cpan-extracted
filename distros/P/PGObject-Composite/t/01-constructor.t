use PGObject::Composite;
use Test::More tests => 5;
use Test::Exception;
use DBI;

my %hash = (
   foo => 'foo',
   bar => 'baz',
   baz => '2',
   id  => '33',
);

my $dbh = 'test_dbh_fake_value';

my $obj = PGObject::Composite->new(%hash);

ok($obj->isa('PGObject::Composite'), 'Object successfully created');

is($obj->set_dbh($dbh), $dbh, 'Set database handle successfully');
is($dbh, $obj->dbh, "database handle cross check");

my $obj2 = PGObject::Composite->new(%hash);
throws_ok { $obj2->dbh } qr/Must override/, 'No db handle for second object';
$obj2->associate($obj);
is($dbh, $obj2->dbh, "database handle cross check after association");

