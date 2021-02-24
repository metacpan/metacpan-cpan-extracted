#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use FindBin;
use blib "$FindBin::Bin/../lib";

use Promise::XS;

{
    my $destroyed = 0;

    my $d = Promise::XS::deferred();

    my $p = do {
        my $obj = OnDestroy->new( sub {
            $destroyed++;
        } );

        $d->promise()->finally( sub { $obj } );
    };

    is( $destroyed, 0, 'promise is alive: reference isn’t reaped' );

    undef $d;
    undef $p;

    is( $destroyed, 1, 'promise is gone: reference is reaped' );
}

{
    my $destroyed = 0;

    my $d = Promise::XS::deferred();

    my $p = do {
        my $obj = OnDestroy->new( sub {
            $destroyed++;
        } );

        $d->promise()->finally( sub { $obj } );
    };

    $p = $p->catch( sub {} );

    is( $destroyed, 0, 'promise is alive: reference isn’t reaped' );

    undef $d;
    undef $p;

    is( $destroyed, 1, 'promise is gone: reference is reaped' );
}

done_testing;

#----------------------------------------------------------------------

package OnDestroy;

sub new { return bless [ $_[1] ], $_[0] }

sub DESTROY {
    defined(${^GLOBAL_PHASE}) && print "DESTROYING at ${^GLOBAL_PHASE}$/";

    $_[0][0]->();
}

1;
