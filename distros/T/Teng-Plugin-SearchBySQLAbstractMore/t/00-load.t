#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Teng::Plugin::SearchBySQLAbstractMore' ) || print "Bail out!
";
}

diag( "Testing Teng::Plugin::SearchBySQLAbstractMore $Teng::Plugin::SearchBySQLAbstractMore::VERSION, Perl $], $^X" );
