use lib 't', 'lib';

use Test::More qw(no_plan);
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use HashClass (auto_deploy => 1);
use Class1 (auto_deploy => 1);

#####################################################################
### SET UP

ok($storage->ping);
my $id;


#####################################################################
### HASH

$thing1 = Class1->create({attrib1 => 'foo'});
$thing2 = Class1->create({attrib1 => 'bar'});
$thing3 = Class1->create({attrib1 => 'baz'});

$owner = HashClass->create({
    attrib1 => 'this class has a Hash Assocition with Class1'
});

$owner->assoc2->{$thing1->attrib1} = $thing1;
$owner->assoc2->{$thing2->attrib1} = $thing2;
$owner->assoc2->{$thing3->attrib1} = $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;

$retrieved = HashClass->retrieve($id);

ok($retrieved->assoc2->{foo}->id eq $thing1->id);
ok($retrieved->assoc2->{bar}->id eq $thing2->id);
ok($retrieved->assoc2->{baz}->id eq $thing3->id);

#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->table_drop($dbh, 'class1');
$storage->util->table_drop($dbh, 'hashclass');
$storage->util->table_drop($dbh, 'hashclass_assoc2_class1');
# $storage->util->sequence_drop($dbh, 'class1');
# $storage->util->sequence_drop($dbh, 'hashclass');
$dbh->commit;

