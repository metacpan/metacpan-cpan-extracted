#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use lib '../lib';
use Promise::ES6;

my $destroyed = 0;

my $p = do {
    my $d = OnDestroy->new( sub {
        $destroyed++;
    } );

    Promise::ES6->new( sub { } )->finally( sub { $d } );
};

is( $destroyed, 0, 'promise is alive: reference isn’t reaped' );

undef $p;

is( $destroyed, 1, 'promise is gone: reference is reaped' );

done_testing;

#----------------------------------------------------------------------

package OnDestroy;

sub new { return bless [ $_[1] ], $_[0] }

sub DESTROY {
    $_[0][0]->();
}

1;
