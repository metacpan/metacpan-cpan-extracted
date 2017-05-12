#!perl

use strict;
use warnings;

use Test::More;
use Test::DNS;

plan skip_all => 'requires AUTHOR_TESTING' unless $ENV{'AUTHOR_TESTING'};

my $dns = Test::DNS->new();

# the CNAME record of a domain
$dns->is_cname( 'www.google.com' => 'www.l.google.com' );

# CNAME in hash
$dns->is_cname( {
    'www.google.com' => 'www.l.google.com',
    'www.perl.org'   => 'varnish-lb.develooper.com',
} );

# CNAME in hash with test_name
$dns->is_cname( {
    'www.google.com' => 'www.l.google.com',
    'www.perl.org'   => 'varnish-lb.develooper.com',
}, 'Checking CNAMES for google.com and perl.org' );

done_testing();
