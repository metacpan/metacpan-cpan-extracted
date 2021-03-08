#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use RxPerl::Test;

use RxPerl::SyncTimers ':all';

use Future;

subtest 'rx_from' => sub {
    my $f = Future->new;
    my $o = rx_from($f);
    $f->done(1, 2);
    obs_is $o, ['1'], 'done future';

    $f = Future->new;
    $o = rx_from($f);
    $f->cancel;
    obs_is $o, [''], 'cancelled future';
};

done_testing;