#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 10;

BEGIN {
    use_ok('Test::BDD::Cucumber::Definitions')             || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::HTTP')       || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::HTTP::In')   || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::HTTP::Ru')   || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::Struct')     || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::Struct::In') || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::Struct::Ru') || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::Zip')        || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::Zip::In')    || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::Zip::Ru')    || print "Bail out!\n";
}

diag("Testing Test::BDD::Cucumber::Definitions $Test::BDD::Cucumber::Definitions::VERSION, Perl $], $^X");
