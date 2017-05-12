#!perl

package TestHeaders;
use Test::More;

sub new { return bless {}, shift }

sub header {
    my ( $self, $key, $value ) = @_;

    if ( $key && $value ) {
        is( $key,   'MySpecialHeader', 'Setting new header'               );
        is( $value, '1.1.1.1',         'Setting correct value for header' );
    } elsif ($key) {
        is( $key, 'X-Forwarded-For',   'Correct old header in TestHeader' );
    }

    return '1.1.1.1';
}

package main;
use strict;
use warnings;

use Test::More tests => 5;
use Perlbal::Plugin::ForwardedFor;

my $headers = TestHeaders->new();
isa_ok( $headers, 'TestHeaders' );

Perlbal::Plugin::ForwardedFor::rewrite_header(
    { req_headers => $headers },
    'MySpecialHeader'
);

