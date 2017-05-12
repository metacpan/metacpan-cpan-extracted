#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;
use Sort::External;

check( \'', "reject a scalar ref" );
check( {}, "reject a hash ref" );
check( [], "reject an array ref" );
my $subref = sub { };
check( $subref, "reject a sub ref" );
sub dummy { }
check( *dummy, "reject a glob ref" );

sub check {
    my ( $bad_val, $message ) = @_;
    my @stuff = ( 'A' .. 'Z' );
    eval {
        my $sortex = Sort::External->new( cache_size => 5 );
        $sortex->feed($_) for @stuff;
        $sortex->feed($bad_val);
        $sortex->finish;
    };
    like( $@, qr/can't handle/, $message );
}
