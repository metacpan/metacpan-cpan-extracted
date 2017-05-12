#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok('Term::Screen::Lite')          || print "Bail out!\n";
    use_ok('Term::Screen::Lite::Generic') || print "Bail out!\n";
    use_ok('Term::Screen::Lite::Win32')   || print "Bail out!\n";
}

diag( "Testing Term::Screen::Lite $Term::Screen::Lite::VERSION, Perl $], $^X" );
