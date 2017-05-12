#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 5;

BEGIN {
    use_ok('PDF::Create')          || print "Bail out!\n";
    use_ok('PDF::Create::Page')    || print "Bail out!\n";
    use_ok('PDF::Create::Outline') || print "Bail out!\n";
    use_ok('PDF::Image::GIF')      || print "Bail out!\n";
    use_ok('PDF::Image::JPEG')     || print "Bail out!\n";
}

diag( "Testing PDF::Create $PDF::Create::VERSION, Perl $], $^X" );
