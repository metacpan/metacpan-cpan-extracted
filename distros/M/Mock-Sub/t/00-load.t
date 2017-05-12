#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 20;


BEGIN {
    use_ok( 'Mock::Sub' ) || print "Bail out!\n";
    use_ok( 'Mock::Sub::Child' ) || print "Bail out!\n";
}

diag( "Testing Mock::Sub $Mock::Sub::VERSION, Perl $], $^X" );

can_ok('Mock::Sub', 'new');
can_ok('Mock::Sub', 'mock');
can_ok('Mock::Sub', 'mocked_subs');
can_ok('Mock::Sub', 'mocked_objects');
can_ok('Mock::Sub', 'mocked_state');
can_ok('Mock::Sub', 'DESTROY');


can_ok('Mock::Sub::Child', 'new');
can_ok('Mock::Sub::Child', '_mock');
can_ok('Mock::Sub::Child', 'unmock');
can_ok('Mock::Sub::Child', 'name');
can_ok('Mock::Sub::Child', 'called');
can_ok('Mock::Sub::Child', 'called_count');
can_ok('Mock::Sub::Child', 'called_with');
can_ok('Mock::Sub::Child', 'reset');
can_ok('Mock::Sub::Child', 'return_value');
can_ok('Mock::Sub::Child', 'side_effect');
can_ok('Mock::Sub::Child', '_check_side_effect');
can_ok('Mock::Sub::Child', 'DESTROY');
