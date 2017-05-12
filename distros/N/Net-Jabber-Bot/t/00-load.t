#!perl -T

# Trap for these modules being avail or we can't do our tests...

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Jabber::Bot' );
}

eval { require Net::Jabber::Bot };
BAIL_OUT("Net::Jabber::Bot not installed", 2) if $@;

diag( "Testing Net::Jabber::Bot $Net::Jabber::Bot::VERSION, Perl $], $^X" );
