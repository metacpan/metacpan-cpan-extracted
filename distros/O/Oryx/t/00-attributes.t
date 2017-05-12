use lib 't', 'lib';

use Test::More tests => 9;
use Oryx;
use Class::Date qw(date now);
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use AttrsClass (auto_deploy => 1);

ok($storage->ping);

my $inst = AttrsClass->create({
    attr_string   => 'a string',
    attr_integer  => 42,
    attr_boolean  => 0,
    attr_float    => 12.34,
    attr_datetime => date('1976-04-15'),
    attr_complex  => {
        foo => 'bar',
        baz => [ 'one', 'II', 3 ]
    }
});


$inst->update;
my $id = $inst->id;

my $retrieved = AttrsClass->retrieve($id);

is($retrieved->attr_string, 'a string');
ok($retrieved->attr_integer == 42);
ok($retrieved->attr_boolean == 0);
ok($retrieved->attr_float == 12.34);

isa_ok($retrieved->attr_datetime, 'Class::Date');
ok($retrieved->attr_datetime->string);
is($retrieved->attr_datetime, '1976-04-15 00:00:00');

is_deeply($retrieved->attr_complex, { foo => 'bar', baz => ['one', 'II', 3]});

my $dbh = $storage->dbh;
$storage->util->table_drop($dbh, 'attrsclass');
# $storage->util->sequence_drop($dbh, 'attrsclass');
$dbh->commit;

