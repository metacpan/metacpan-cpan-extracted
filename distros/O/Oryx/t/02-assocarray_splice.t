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
### ARRAY SPLICE

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
my $splice_in1 = Class1->create({attrib1 => 'in1'});
my $splice_in2 = Class1->create({attrib1 => 'in2'});

my ($splice_out) = splice @{$retrieved->assoc1}, 1, 1, ($splice_in1, $splice_in2);

ok($splice_out->id eq $thing2->id);
ok(scalar @{$retrieved->assoc1} eq 4);

ok($retrieved->assoc1->[0]->id eq $thing1->id);
ok($retrieved->assoc1->[1]->id eq $splice_in1->id);
ok($retrieved->assoc1->[2]->id eq $splice_in2->id);
ok($retrieved->assoc1->[3]->id eq $thing3->id);


#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->table_drop($dbh, 'assocclass');
$storage->util->table_drop($dbh, 'assocclass_assoc1_class1');
$storage->util->table_drop($dbh, 'class1');
# $storage->util->sequence_drop($dbh, 'assocclass');
# $storage->util->sequence_drop($dbh, 'class1');
$dbh->commit;


