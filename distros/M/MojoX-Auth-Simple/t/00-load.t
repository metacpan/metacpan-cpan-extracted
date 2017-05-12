#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'MojoX::Auth::Simple' ) || print "Bail out!
";
}

diag( "Testing MojoX::Auth::Simple $MojoX::Auth::Simple::VERSION, Perl $], $^X" );
