#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'RT::Extension::TimeWorkedReport' );
}

diag( "Testing RT::Extension::TimeWorkedReport $RT::Extension::TimeWorkedReport::VERSION, Perl $], $^X" );

