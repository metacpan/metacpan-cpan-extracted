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
### ARRAY SHIFT

$thing1 = Class1->create({attrib1 => 'foo'});
$thing2 = Class1->create({attrib1 => 'bar'});
$thing3 = Class1->create({attrib1 => 'baz'});

$owner = AssocClass->create({
    attrib1 => 'this class has an Array Assocition with Class1'
});
push @{$owner->assoc1}, $thing1;
push @{$owner->assoc1}, $thing2;
push @{$owner->assoc1}, $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;
$retrieved = AssocClass->retrieve($id);

my $shifted1 = shift @{$retrieved->assoc1};
my $shifted2 = shift @{$retrieved->assoc1};
my $shifted3 = shift @{$retrieved->assoc1};

ok(not scalar @{$retrieved->assoc1});

ok($shifted1->id eq $thing1->id);
ok($shifted2->id eq $thing2->id);
ok($shifted3->id eq $thing3->id);


#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->table_drop($dbh, 'assocclass');
$storage->util->table_drop($dbh, 'assocclass_assoc1_class1');
$storage->util->table_drop($dbh, 'class1');
# $storage->util->sequence_drop($dbh, 'assocclass');
# $storage->util->sequence_drop($dbh, 'class1');
$dbh->commit;

