#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;

my %started = ();
resource foo =>
    preload     => 1,
    init        => sub { $started{$_[1]}++ };
resource bar =>
    init        => sub { $started{$_[1]}++ };
resource quux =>
    init        => sub { 42 };

is silo->quux, 42, 'unconditional resource';
is_deeply \%started, {}, 'no preload called = empty';

silo->ctl->preload;
is_deeply \%started, { foo => 1 }, 'preload called = preloaded';

done_testing;
