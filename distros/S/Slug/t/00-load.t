#!perl
use 5.008003;
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok( 'Slug' ) || print "Bail out!\n";
}

can_ok('Slug', 'slug');
can_ok('Slug', 'slug_ascii');
can_ok('Slug', 'slug_custom');
can_ok('Slug', 'include_dir');

diag( "Testing Slug $Slug::VERSION, Perl $], $^X" );
