use strict;
use warnings;

use Test::More tests => 6;

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

ok(defined($NLQuestion->loadInput("examples/example-t6-9.qald") == 1), "loadInput (q t6-9) work");

my $question = $NLQuestion->getQuestionFromId("qald-4_biomedical_test-6");

my $outStr;
my $count = $NLQuestion->Questions2Queries(\$outStr);
# warn "$outStr\n";
# warn $count;
ok($count == 2, "Questions2Queries (q1 t6-9) works");
