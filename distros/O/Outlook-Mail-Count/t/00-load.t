#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Outlook::Mail::Count' ) || print "Bail out!\n";
    use_ok( 'Outlook::Mail::Count' ) || print "Bail out!\n";
}

diag( "Testing Outlook::Mail::Count $Outlook::Mail::Count::VERSION, Perl $], $^X" );
