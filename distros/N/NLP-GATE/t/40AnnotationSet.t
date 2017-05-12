#!perl

use Test::More tests => 17;
use Data::Dumper;

BEGIN { use_ok NLP::GATE }
  
diag( "Testing NLP::GATE::AnnotationSet $NLP::GATE::AnnotationSet::VERSION, Perl $], $^X" );

can_ok(NLP::GATE::AnnotationSet, qw(new  add get getAsArray getAsArrayRef getByIndex getByOffset size  ) ) ;

my $annset = NLP::GATE::AnnotationSet->new();
isa_ok($annset, 'NLP::GATE::AnnotationSet');

is($annset->size(),0,"size after new is 0");

my $ann1 = NLP::GATE::Annotation->new("AType1",10,20);
$ann1->setFeature("f1","value1");

my $ann2 = $ann1->clone();
is_deeply($ann1,$ann2,"cloned annotations equal");

my $empty = NLP::GATE::AnnotationSet->new();

$annset->add($ann1);
my $ret = $annset->getByIndex(0);
is_deeply($ann1,$ret,"returned annotation equal");

$ret = $annset->get("nonexist");
is($ret->size(),0,"empty if searching for nonexisting type");

$ret = $annset->get("AType1");
is($ret->size(),1,"nonempty if searching for existing");

$ret = $ret->getByIndex(0);
is_deeply($ann1,$ret,"found equal to original");

my @anns = $annset->getAsArray();
is(scalar @anns,1,"correct size of array for getAsArray");
is_deeply($ann1,$anns[0],"As returned by getAsArray");

$ret = $annset->getByIndex(0);

my $anns = $annset->getAsArrayRef();
is(scalar @{$anns},1,"correct size of array for getAsArrayRef");
is_deeply($ann1,$anns->[0],"as retruend by getAsArrayRef");

$ret = $annset->get(undef);
is_deeply($annset,$ret,"get without condition is null op");

$ret = $annset->get("AType1",{f1=>value1});
is_deeply($annset,$ret,"search using feature value exact");

$ret = $annset->get("AType1",{f1=>VALUE1},"nocase");
is_deeply($annset,$ret,"search using feature value nocase");


$ret = $annset->get("AType1",{f1=>VALUE2},"nocase");
is_deeply($empty,$ret,"search using feature value nocase");
