#!perl -T

use warnings;
use strict;

use Test::More tests => 1;

BEGIN {
    use_ok( 'POE::Component::Schedule' );
}

diag( "Testing POE::Component::Schedule ".POE::Component::Schedule->VERSION.", POE ".POE->VERSION.", Perl $], $^X" );
