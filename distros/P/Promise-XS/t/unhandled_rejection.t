#!/usr/bin/perl

package t::unhandled_rejection;

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Promise::XS;

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
