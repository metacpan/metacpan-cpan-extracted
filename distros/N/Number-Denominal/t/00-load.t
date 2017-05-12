#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

BEGIN {
    use_ok('Carp');
    use_ok('List::ToHumanString');
    use_ok('Exporter');
    use_ok( 'Number::Denominal' ) || print "Bail out!\n";
}

$Number::Denominal::VERSION ||= '[undef]';

diag( "Testing Number::Denominal $Number::Denominal::VERSION, Perl $], $^X" );
