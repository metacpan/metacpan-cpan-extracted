#!/usr/bin/perl

package t::unhandled_rejection;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Promise::XS;

# should not warn because catch() silences
{
    my $d = Promise::XS::deferred();

    my $p = $d->promise()->catch( sub { } );

    $d->reject("nonono");
}

# should warn because finally() rejects
{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        my $p = $d->promise();

        $p->then( sub {
            die "nonono";
        } );

        $d->resolve(234);
    }

    cmp_deeply(
        \@w,
        [ re( qr<nonono> ) ],
        'die() in then() triggers warning when promise was never an SV',
    ) or diag explain \@w;
}

{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        my $p = $d->promise();

        my @caught;

        my $p2 = $p->then( sub {
            return Promise::XS::rejected(666);
        } )->catch( sub {
            push @caught, shift;
        } );

        $d->resolve(234);

        is_deeply(\@caught, [666], 'returned rejection caught');
    }

    cmp_deeply(
        \@w,
        [ ],
        'returned rejected() propagates as expected, doesn’t trigger unhandled warning',
    );
}

{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        my $p = $d->promise();

        my $p2 = $p->then( sub {
            die "nonono";
        } );

        undef $p2;

        $d->resolve(234);
    }

    cmp_deeply(
        \@w,
        [ re( qr<nonono> ) ],
        'die() in then() triggers warning when promise was an SV that’s GCed early',
    );
}

{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        my $p = $d->promise();

        $p->then( sub {
            return Promise::XS::rejected(666);
        } );

        $d->resolve(234);
    }

    cmp_deeply(
        \@w,
        [ re( qr<666> ) ],
        'return rejected in then() triggers warning when promise itself never was an SV',
    );
}

{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        $d->reject("nonono");
    }

    cmp_deeply(
        \@w,
        [ re( qr/nonono/ ) ],
        'warning if there was never a perl-ified promise',
    ) or diag explain \@w;
}

# should warn because $d->promise() is uncaught
{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        # The finally() does not create a separate result.

        my $p = $d->promise()->finally( sub { } );
        $d->reject("nonono");
    }

    cmp_deeply(
        \@w,
        [ re( qr<nonono> ) ],
        'rejection with finally but no catch triggers 1 warning',
    ) or diag explain \@w;
}

{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        # The finally() does not create a separate result.
        my $p = $d->promise()->finally( sub { } );

        $d->reject("nonono");
    }

    cmp_deeply(
        \@w,
        [ re( qr<nonono> ) ],
        'rejection with finally but no catch triggers 1 warning',
    ) or diag explain \@w;
}

# should not warn because finally() doesn't get its own result
{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        my $p = $d->promise();

        my $f = $p->finally( sub { } );

        $p->catch( sub { } );

        $d->reject("nonono");
    }

    cmp_deeply(
        \@w,
        [ ],
        'rejected finally is uncaught, but rejection is caught elsewhere',
    );
}

# should NOT warn because finally() rejection is caught
{
    my @w;
    local $SIG{'__WARN__'} = sub { push @w, @_ };

    {
        my $d = Promise::XS::deferred();

        my $p = $d->promise();

        my $f = $p->finally( sub { } )->catch( sub { } );

        $p->catch( sub { } );

        $d->reject("awful");
    }

    cmp_deeply(
        \@w,
        [],
        'no warning when finally passthrough rejection is caught',
    ) or diag explain \@w;
}

#----------------------------------------------------------------------

{
    my $d = Promise::XS::deferred();

    my $p = $d->resolve(123)->promise()->then( sub {
        my ($value) = @_;

        return Promise::XS::rejected( { message => 'oh my god', value => $value } );
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });

    my $got;

    $p->then( sub { $got = shift } );

    is_deeply $got, { message => 'oh my god', value => 123 }, 'got expected';
}

#----------------------------------------------------------------------

{
    my $d = Promise::XS::deferred();

    my $p = $d->resolve(123)->promise()->then( sub {
        my ($value) = @_;

        return bless [], 'ForeignRejectedPromise';
    })->catch(sub {
        my ($reason) = @_;
        return $reason;
    });

    my $got;

    $p->then( sub { $got = shift } );

    is_deeply $got, 'ForeignRejectedPromise', 'got expected from foreign rejected';
}

done_testing();

#----------------------------------------------------------------------

package ForeignRejectedPromise;

sub then {
    my ($self, $on_res, $on_rej) = @_;

    $on_rej->(ref $self);

    return $self;
}

1;
