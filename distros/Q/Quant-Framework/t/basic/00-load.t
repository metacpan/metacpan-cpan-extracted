#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok('Quant::Framework')                    || print "Bail out!\n";
    use_ok('Quant::Framework::CorporateAction')   || print "Bail out!\n";
    use_ok('Quant::Framework::Utils::MarketData') || print "Bail out!\n";
    use_ok('Quant::Framework::Utils::Test')       || print "Bail out!\n";
    use_ok('Quant::Framework::Utils::Types')      || print "Bail out!\n";
}

diag("Testing Quant::Framework $Quant::Framework::VERSION, Perl $], $^X");
