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


my $thing3 = Class1->create({attrib1 => 'thing 3'});
my $thing0 = Class1->create({attrib1 => 'thing 0'});
my $thing4 = Class1->create({attrib1 => 'thing 4'});
my $thing2 = Class1->create({attrib1 => 'thing 2'});
my $thing1 = Class1->create({attrib1 => 'thing 1'});

$thing0->update; $thing0->commit;
$thing1->update; $thing1->commit;
$thing2->update; $thing2->commit;
$thing3->update; $thing3->commit;
$thing4->update; $thing4->commit;

my @things = Class1->search({attrib1 => 'thing%'}, ['attrib1']);

is($things[0]->attrib1, 'thing 0');
is($things[1]->attrib1, 'thing 1');
is($things[2]->attrib1, 'thing 2');
is($things[3]->attrib1, 'thing 3');
is($things[4]->attrib1, 'thing 4');

@things = Class1->search({attrib1 => 'thing%'}, ['attrib1'], 3, 1);
is(scalar(@things), 3);
is($things[0]->attrib1, 'thing 1');
is($things[1]->attrib1, 'thing 2');
is($things[2]->attrib1, 'thing 3');

#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->table_drop($dbh, 'assocclass');
$storage->util->table_drop($dbh, 'assocclass_assoc1_class1');
$storage->util->table_drop($dbh, 'class1');
# $storage->util->sequence_drop($dbh, 'assocclass');
# $storage->util->sequence_drop($dbh, 'class1');
$dbh->commit;

