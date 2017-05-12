# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Def.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 23;
}

#########################

use OBO::Core::Def;
use OBO::Core::Dbxref;
use strict;

# three new def's
my $def1 = OBO::Core::Def->new();
my $def2 = OBO::Core::Def->new();
my $def3 = OBO::Core::Def->new();

ok($def2->dbxref_set_as_string() eq '[]');

$def1->text('Definition #1 given by vm');
ok($def1->text() eq 'Definition #1 given by vm');
$def2->text('Definition #2 given by ls');
ok($def2->text() eq 'Definition #2 given by ls');
$def3->text('Definition #3 given by ea');
ok($def3->text() eq 'Definition #3 given by ea');

my $ref1 = OBO::Core::Dbxref->new();
my $ref2 = OBO::Core::Dbxref->new();
my $ref3 = OBO::Core::Dbxref->new();

$ref1->name('APO:vm');
$ref2->name('APO:ls');
$ref3->name('APO:ea');

ok($ref3->db() eq 'APO');
ok($ref3->acc() eq 'ea');

my $dbxref_set1 = OBO::Util::DbxrefSet->new();
$dbxref_set1->add($ref1);

my $dbxref_set2 = OBO::Util::DbxrefSet->new();
$dbxref_set2->add($ref2);

my $dbxref_set3 = OBO::Util::DbxrefSet->new();
$dbxref_set3->add($ref3);

$def1->dbxref_set($dbxref_set1);
$def2->dbxref_set($dbxref_set2);
$def3->dbxref_set($dbxref_set3);

ok(!$def3->equals($def2));
ok($def3->equals($def3));

# dbxref_set_as_string
ok($def2->dbxref_set_as_string() eq '[APO:ls]');

$def2->dbxref_set_as_string('[APO:lc {opt=chitis}]');
ok($def2->dbxref_set_as_string() eq '[APO:lc {opt=chitis}, APO:ls]');

$def2->dbxref_set_as_string('[APO:ab "Antonio Quispe"]');
ok($def2->dbxref_set_as_string() eq '[APO:ab "Antonio Quispe", APO:lc {opt=chitis}, APO:ls]');

$def2->dbxref_set_as_string('[APO:vm, APO:ee {opt=chitis}, APO:ea "Erick Antezana" {opt=first}]');

my @refs_def2 = $def2->dbxref_set()->get_set();
my %r_def2;
foreach my $ref_def2 (@refs_def2) {
	$r_def2{$ref_def2->name()} = $ref_def2->name();
}
ok($r_def2{'APO:vm'} eq 'APO:vm');
ok($r_def2{'APO:ls'} eq 'APO:ls');
ok($r_def2{'APO:ea'} eq 'APO:ea');
ok($def2->dbxref_set_as_string() eq '[APO:ab "Antonio Quispe", APO:ea "Erick Antezana" {opt=first}, APO:ee {opt=chitis}, APO:lc {opt=chitis}, APO:ls, APO:vm]');

$def2->dbxref_set_as_string('[http://mydomain.com/key1=value1&key2=value2]');
ok($def2->dbxref_set_as_string() eq '[APO:ab "Antonio Quispe", APO:ea "Erick Antezana" {opt=first}, APO:ee {opt=chitis}, APO:lc {opt=chitis}, APO:ls, APO:vm, http://mydomain.com/key1=value1&key2=value2]');

$def2->dbxref_set_as_string('[ABC:john]');
ok($def2->dbxref_set_as_string() eq '[ABC:john, APO:ab "Antonio Quispe", APO:ea "Erick Antezana" {opt=first}, APO:ee {opt=chitis}, APO:lc {opt=chitis}, APO:ls, APO:vm, http://mydomain.com/key1=value1&key2=value2]');

$def2->dbxref_set_as_string('[ABC:john]');
ok($def2->dbxref_set_as_string() eq '[ABC:john, APO:ab "Antonio Quispe", APO:ea "Erick Antezana" {opt=first}, APO:ee {opt=chitis}, APO:lc {opt=chitis}, APO:ls, APO:vm, http://mydomain.com/key1=value1&key2=value2]');

$def2->dbxref_set_as_string('[ABC:john, ABC:john]');
ok($def2->dbxref_set_as_string() eq '[ABC:john, APO:ab "Antonio Quispe", APO:ea "Erick Antezana" {opt=first}, APO:ee {opt=chitis}, APO:lc {opt=chitis}, APO:ls, APO:vm, http://mydomain.com/key1=value1&key2=value2]');

my $def4 = OBO::Core::Def->new();
$def4->dbxref_set_as_string('[AAA:hpc "hugo\, paco\, luis", BBB:p "paco"]');
ok($def4->dbxref_set_as_string() eq '[AAA:hpc "hugo\, paco\, luis", BBB:p "paco"]');

my $def5 = OBO::Core::Def->new();
$def5->dbxref_set_as_string('[AAA:hpc "hugo, paco, luis", BBB:p "paco"]');
ok($def5->dbxref_set_as_string() eq '[AAA:hpc "hugo\, paco\, luis", BBB:p "paco"]');

my $def6 = OBO::Core::Def->new();
$def6->dbxref_set_as_string('[AAA:hpc {opt=first}, BBB:p "paco"]');
ok($def6->dbxref_set_as_string() eq '[AAA:hpc {opt=first}, BBB:p "paco"]');

ok(1);
