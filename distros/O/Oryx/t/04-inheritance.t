use lib 't', 'lib';

use Test::More tests => 7;
use Oryx;
use YAML;
use Data::Dumper;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use Oryx::Class (auto_deploy => 1);
use Child1;

#####################################################################
### SET UP

ok($storage->ping);
my $id;

#####################################################################
### TEST

my $child = Child1->create({
    child_attrib1 => 'child attribute',
    parent1_attrib => 'from parent 1',
    parent2_attrib => 'from parent 2',
});

$child->update;
$child->dbh->commit;
$id = $child->id;
$child->remove_from_cache;

my $retrieved = Child1->retrieve($id);

ok($retrieved->parent1_attrib eq 'from parent 1');
ok($retrieved->parent2_attrib eq 'from parent 2');

ok($retrieved->child_attrib1 eq 'child attribute');
ok($retrieved->isa('Parent1'));
ok($retrieved->isa('Parent2'));
ok($retrieved->isa('Child1'));

