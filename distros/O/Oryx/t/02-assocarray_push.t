use lib 't', 'lib';

use Test::More qw(no_plan);
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use AssocClass (auto_deploy => 1);
use Class1 (auto_deploy => 1);

#####################################################################
### SET UP

ok($storage->ping);

my $id;
my $owner;
my $retrieved;


#####################################################################
### ARRAY PUSH

my $thing1 = Class1->create({attrib1 => 'foo'});
my $thing2 = Class1->create({attrib1 => 'bar'});
my $thing3 = Class1->create({attrib1 => 'baz'});

$owner = AssocClass->create({
    attrib1 => 'this class has an Array Assocition with TestClass'
});
push @{$owner->assoc1}, $thing1;
push @{$owner->assoc1}, $thing2;
push @{$owner->assoc1}, $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;
$retrieved = AssocClass->retrieve($id);

ok($retrieved->assoc1->[0]->attrib1 eq 'foo');
ok($retrieved->assoc1->[1]->attrib1 eq 'bar');
ok($retrieved->assoc1->[2]->attrib1 eq 'baz');


#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->table_drop($dbh, 'assocclass');
$storage->util->table_drop($dbh, 'assocclass_assoc1_class1');
$storage->util->table_drop($dbh, 'class1');
# $storage->util->sequence_drop($dbh, 'assocclass');
# $storage->util->sequence_drop($dbh, 'class1');
$dbh->commit;

