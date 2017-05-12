#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Robotics::IRobot' ) || print "Bail out!
";
}

diag( "Testing Robotics::IRobot $Robotics::IRobot::VERSION, Perl $], $^X" );
