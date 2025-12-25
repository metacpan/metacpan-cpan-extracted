#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'NOAA::Aurora' ) || print "Bail out!\n";
}

diag( "Testing NOAA::Aurora $NOAA::Aurora::VERSION, Perl $], $^X" );
