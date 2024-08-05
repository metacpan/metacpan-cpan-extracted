#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use RxPerl::Test;

use RxPerl::SyncTimers ':all';

use Mojo::IOLoop;

RxPerl::SyncTimers->set_promise_class('Mojo::Promise');

my $o = rx_of(10, 20, 30);
my (@vals, @errs);

(@vals, @errs) = ();
first_value_from($o)->then(
    sub { push @vals, $_[0] },
    sub { push @errs, $_[0] },
);
Mojo::IOLoop->one_tick;
is [\@vals, \@errs], [[10], []], 'first_value_from w/ value';

(@vals, @errs) = ();
last_value_from($o)->then(
    sub { push @vals, $_[0] },
    sub { push @errs, $_[0] },
);
Mojo::IOLoop->one_tick;
is [\@vals, \@errs], [[30], []], 'last_value_from w/ value';

$o = rx_of();

(@vals, @errs) = ();
first_value_from($o)->then(
    sub { push @vals, $_[0] },
    sub { push @errs, $_[0] },
);
Mojo::IOLoop->one_tick;
is [\@vals, \@errs], [[], ['no elements in sequence']], 'first_value_from w/o value';

(@vals, @errs) = ();
last_value_from($o)->then(
    sub { push @vals, $_[0] },
    sub { push @errs, $_[0] },
);
Mojo::IOLoop->one_tick;
is [\@vals, \@errs], [[], ['no elements in sequence']], 'last_value_from w/o value';

done_testing;
