#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok('Test::BDD::Cucumber::Definitions')             || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::HTTP')       || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::HTTP::Util') || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::Data')       || print "Bail out!\n";
    use_ok('Test::BDD::Cucumber::Definitions::Data::Util') || print "Bail out!\n";
}

diag("Testing Test::BDD::Cucumber::Definitions $Test::BDD::Cucumber::Definitions::VERSION, Perl $], $^X");
