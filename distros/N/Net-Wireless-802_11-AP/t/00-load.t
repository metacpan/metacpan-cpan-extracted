#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Wireless::802_11::AP' ) || print "Bail out!
";
}

diag( "Testing Net::Wireless::802_11::AP $Net::Wireless::802_11::AP::VERSION, Perl $], $^X" );
