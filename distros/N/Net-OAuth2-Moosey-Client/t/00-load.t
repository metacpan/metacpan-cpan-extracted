#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::OAuth2::Moosey::Client' ) || print "Bail out!
";
}

diag( "Testing Net::OAuth2::Moosey::Client $Net::OAuth2::Moosey::Client::VERSION, Perl $], $^X" );
