#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Mojo::Command::Generate::InitScript' ) || print "Bail out!
";
}

diag( "Testing Mojo::Command::Generate::InitScript $Mojo::Command::Generate::InitScript::VERSION, Perl $], $^X" );
