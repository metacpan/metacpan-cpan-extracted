# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synonym.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 35;
}

#########################

use OBO::Core::Synonym;
use OBO::Core::Dbxref;

my $syn1 = OBO::Core::Synonym->new();
my $syn2 = OBO::Core::Synonym->new();
my $syn3 = OBO::Core::Synonym->new();
my $syn4 = OBO::Core::Synonym->new();

# scope
ok(!defined $syn1->scope());
$syn1->scope('EXACT');
$syn2->scope('BROAD');
$syn3->scope('NARROW');
$syn4->scope('NARROW');

# def
my $def1 = OBO::Core::Def->new();
my $def2 = OBO::Core::Def->new();
my $def3 = OBO::Core::Def->new();
my $def4 = OBO::Core::Def->new();

$def1->text('Hola mundo1');
$def2->text('Hola mundo2');
$def3->text('Hola mundo3');
$def4->text('Hola mundo3');

my $ref1 = OBO::Core::Dbxref->new();
my $ref2 = OBO::Core::Dbxref->new();
my $ref3 = OBO::Core::Dbxref->new();
my $ref4 = OBO::Core::Dbxref->new();

$ref1->name('APO:vm');
$ref2->name('APO:ls');
$ref3->name('APO:ea');
$ref4->name('APO:ea');

my $refs_set1 = OBO::Util::DbxrefSet->new();
$refs_set1->add_all($ref1, $ref2, $ref3, $ref4);
$def1->dbxref_set($refs_set1);
$syn1->def($def1);
ok($syn1->def()->text() eq 'Hola mundo1');
ok($syn1->def()->dbxref_set()->size == 3);

my $refs_set2 = OBO::Util::DbxrefSet->new();
ok($syn1->def()->dbxref_set()->size == 3);
ok($syn2->def()->dbxref_set()->size == 0);
$refs_set2->add($ref2);
$def2->dbxref_set($refs_set2);
$syn2->def($def2);
ok($syn2->def()->text() eq 'Hola mundo2');
ok($syn2->def()->dbxref_set()->size == 1);
ok(($syn2->def()->dbxref_set()->get_set())[0]->equals($ref2));

my $refs_set3 = OBO::Util::DbxrefSet->new();
ok($syn1->def()->dbxref_set()->size == 3);
ok($syn2->def()->dbxref_set()->size == 1);
ok($syn3->def()->dbxref_set()->size == 0);
$refs_set3->add($ref3);
$def3->dbxref_set($refs_set3);
$syn3->def($def3);
ok($syn3->def()->text() eq 'Hola mundo3');
ok($syn3->def()->dbxref_set()->size == 1);
ok(($syn3->def()->dbxref_set()->get_set())[0]->name() eq 'APO:ea');

my $refs_set4 = OBO::Util::DbxrefSet->new();
ok($syn1->def()->dbxref_set()->size == 3);
ok($syn2->def()->dbxref_set()->size == 1);
ok($syn3->def()->dbxref_set()->size == 1);
ok($syn4->def()->dbxref_set()->size == 0);
$refs_set4->add($ref4);
$def4->dbxref_set($refs_set4);
$syn4->def($def4);
ok($syn4->def()->text() eq 'Hola mundo3');
ok($syn4->def()->dbxref_set()->size == 1);
ok(($syn4->def()->dbxref_set()->get_set())[0]->name() eq 'APO:ea');

# syn3 and syn4 are equal
ok($syn3->equals($syn4));
ok($syn3->scope() eq $syn4->scope());
ok($syn3->def()->equals($syn4->def()));
ok($syn3->def()->text() eq $syn4->def()->text());
ok(($syn3->def()->dbxref_set())->equals($syn4->def()->dbxref_set()));

# def as string
ok($syn3->def_as_string() eq '"Hola mundo3" [APO:ea]');
$syn3->def_as_string('This is a dummy synonym', '[APO:ls, APO:ea "Erick Antezana", APO:vm, http://mydomain.com/key1=value1&key2=value2]');
ok($syn3->def()->text() eq 'This is a dummy synonym');
my @refs_syn3 = $syn3->def()->dbxref_set()->get_set();
my %r_syn3;
foreach my $ref_syn3 (@refs_syn3) {
	$r_syn3{$ref_syn3->name()} = $ref_syn3->name();
}
ok($syn3->def()->dbxref_set()->size == 4);
ok($r_syn3{'APO:vm'} eq 'APO:vm');
ok($r_syn3{'APO:ls'} eq 'APO:ls');
ok($r_syn3{'APO:ea'} eq 'APO:ea');
ok($r_syn3{'http://mydomain.com/key1=value1&key2=value2'} eq 'http://mydomain.com/key1=value1&key2=value2');
ok($syn3->def_as_string() eq '"This is a dummy synonym" [APO:ea "Erick Antezana", APO:ls, APO:vm, http://mydomain.com/key1=value1&key2=value2]');

# synonym_type_name
$syn1->synonym_type_name('UK_SPELLING');
ok(1);