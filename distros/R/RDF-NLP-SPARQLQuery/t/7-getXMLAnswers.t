use strict;
use warnings;

use Test::More tests => 8;

use RDF::NLP::SPARQLQuery;

my $NLQuestion = RDF::NLP::SPARQLQuery->new();
ok( defined($NLQuestion) && ref $NLQuestion eq 'RDF::NLP::SPARQLQuery',     'new() works' );

$NLQuestion->verbose(0);

$NLQuestion->configFile("t/nlquestion.rc");
ok($NLQuestion->configFile eq "t/nlquestion.rc", "configFile works (second version)");

$NLQuestion->loadConfig;
ok(defined($NLQuestion->config), "loadconfig and config work (second version)");

$NLQuestion->format("XMLANSWERS");

# $NLQuestion->_loadSemtypecorresp('en');
ok(defined($NLQuestion->semtypecorresp),"_loadSemtypecorresp works");

ok(defined($NLQuestion->loadInput("examples/example1.qald") == 1), "loadInput (q1) work");

my $question = $NLQuestion->getQuestionFromId("qald-4_biomedical_train-1");

ok(scalar(@{$question->_sortedSemanticUnits}) == 3, "getSortedSemanticUnits works");

my $outStr = "";
my $count = $NLQuestion->Questions2Queries(\$outStr);
# warn "$outStr\n";
# warn $count;
ok($count == 1, "Questions2Queries (q1) works");
ok(scalar(@{$question->_sortedSemanticUnits}) == 3, "getSortedSemanticUnits works");

# ok(defined($NLQuestion->loadInput("examples/example17.qald") == 1), "loadInput (q17) work");

# $question = $NLQuestion->getQuestionFromId("qald-4_biomedical_train-17");
# my $count = $NLQuestion->Questions2Queries(*STDERR);
# warn $count;
# ok($count == 1, "Questions2Queries (q17) works");
