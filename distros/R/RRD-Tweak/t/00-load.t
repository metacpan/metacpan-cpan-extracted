#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'RRD::Tweak' ) || print "Bail out!
";
}

diag( "Testing RRD::Tweak $RRD::Tweak::VERSION, Perl $], $^X" );
