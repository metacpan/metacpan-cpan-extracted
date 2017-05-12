use lib 't', 'lib';

use Test::More qw(no_plan);
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use Oryx::Class (auto_deploy => 1);
use AssocClass;
use Class2;
use DoubleRef;

#####################################################################
### SET UP

ok($storage->ping);
my $id;
my $owner;
my $retrieved;


#####################################################################
### Reference

$owner = AssocClass->create({attrib1 => 'foo'});
my $referree = Class2->create({attrib1 => 'referree'});
$owner->assoc2($referree);
$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;

$retrieved = AssocClass->retrieve($id);
ok($retrieved->assoc2->attrib1 eq 'referree');

my $thing1 = Class2->create({ attrib1 => 'thing1' });
my $thing2 = Class2->create({ attrib1 => 'thing2' });

my $dblref = DoubleRef->create({ attrib1 => 'dblref' });
$dblref->first_ref($thing1);
$dblref->second_ref($thing2);

$dblref->update;
$dblref->commit;

$id = $dblref->id;


