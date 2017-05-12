#!perl -T
use 5.006;
use strict;
use Test::More tests => 3;

BEGIN {
    use_ok( 'Net::RFC::Search' ) || print "Bail out!\n";
}

my $rfc_search = Net::RFC::Search->new;
isa_ok($rfc_search, 'Net::RFC::Search');
isa_ok($rfc_search->_ua, 'LWP::UserAgent');

