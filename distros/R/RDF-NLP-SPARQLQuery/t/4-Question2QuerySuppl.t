use strict;
use warnings;

use Test::More tests => 8;

use RDF::NLP::SPARQLQuery;

my $NLQuestion = RDF::NLP::SPARQLQuery->new();
$NLQuestion->verbose(0);
ok( defined($NLQuestion) && ref $NLQuestion eq 'RDF::NLP::SPARQLQuery',     'new() works' );

$NLQuestion->configFile("t/nlquestion.rc");
ok($NLQuestion->configFile eq "t/nlquestion.rc", "configFile works (second version)");

$NLQuestion->loadConfig;
ok(defined($NLQuestion->config), "loadconfig and config work (second version)");


# $NLQuestion->_loadSemtypecorresp('en');
ok(defined($NLQuestion->semtypecorresp),"_loadSemtypecorresp works");

ok(defined($NLQuestion->loadInput("examples/example1.qald") == 1), "loadInput (q1) work");

my $question = $NLQuestion->getQuestionFromId("qald-4_biomedical_train-1");

ok(scalar(@{$question->_sortedSemanticUnits}) == 3, "getSortedSemanticUnits works");

my $count;

ok(defined($NLQuestion->loadInput("examples/example17.qald") == 1), "loadInput (q17) work");

$question = $NLQuestion->getQuestionFromId("qald-4_biomedical_train-17");
# warn $question->docId;

my $outStr;
$count = $NLQuestion->Questions2Queries(\$outStr);
#warn "$outStr\n";
# warn $count;
ok($count == 2, "Questions2Queries (q17) works");
