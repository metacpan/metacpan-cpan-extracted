#!perl -T

use Test::Most;

BEGIN {
    use_ok( 'OpusVL::Preferences' ) || print "Bail out!
";
}

diag( "Testing OpusVL::Preferences $OpusVL::Preferences::VERSION, Perl $], $^X" );

use_ok 'OpusVL::Preferences::Schema';

done_testing;
