use strict;
use warnings;

use Test::More tests => 12;

use RDF::NLP::SPARQLQuery;

my $NLQuestion = RDF::NLP::SPARQLQuery->new();
ok( defined($NLQuestion) && ref $NLQuestion eq 'RDF::NLP::SPARQLQuery',     'new() works' );

$NLQuestion->configFile("t/nlquestion.rc");
ok($NLQuestion->configFile eq "t/nlquestion.rc", "configFile works (second version)");

$NLQuestion->loadConfig;
ok(defined($NLQuestion->config), "loadconfig and config work (second version)");


# $NLQuestion->_loadSemtypecorresp('en');
ok(defined($NLQuestion->semtypecorresp),"_loadSemtypecorresp works");

my $return = $NLQuestion->loadInput("examples/example1.qald");
ok(defined($return eq "qald-4_biomedical_train-1"), "loadInput work");

ok(scalar($NLQuestion->getQuestionList) == 1, "make question works");

my $question = $NLQuestion->getQuestionFromId("qald-4_biomedical_train-1");
ok($question->language eq "EN", "language OK\n");
ok(scalar(@{$question->sentences}) == 1, "sentences OK\n");
ok(scalar(@{$question->postags}) == 7, "postags OK\n");
ok(scalar(@{$question->semanticUnits}) == 3, "semanticUnits OK\n");

# warn "\n";
# warn $question->semanticUnits->[0]->{'semanticUnit'} . "\n";
# warn join(",", keys %{$question->semanticUnits->[0]->{'semanticTypes'}}) . "\n";

ok(scalar(keys %{$question->semanticUnits->[0]->{'semanticTypes'}}) == 1, "semanticTypes OK\n");

ok($question->semanticUnits->[0]->{'semanticUnit'} eq "diseases" &&
   scalar(keys %{$question->semanticUnits->[0]->{'semanticTypes'}}) == 1 &&
   join("", keys %{$question->semanticUnits->[0]->{'semanticTypes'}}) eq "disease", "semanticTypes OK\n");
