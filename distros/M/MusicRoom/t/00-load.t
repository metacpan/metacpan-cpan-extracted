#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MusicRoom' ) || print "Bail out!
";
}

diag( "Testing MusicRoom $MusicRoom::VERSION, Perl $], $^X" );
