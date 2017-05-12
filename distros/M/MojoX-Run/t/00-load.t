#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'MojoX::Run' ) || print "Bail out!
";
}

diag( "Testing MojoX::Run $MojoX::Run::VERSION, Perl $], $^X" );
