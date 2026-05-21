#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;

# TODO verify that a 'require'd module preload is attempted!

my %started = ();
resource foo =>
    preload     => 1,
    init        => sub { $started{$_[1]}++ };
resource bar =>
    init        => sub { $started{$_[1]}++ };
resource quux =>
    init        => sub { 42 };
resource with_args =>
    preload     => [ 'first', 'last' ],
    argument    => qr/.*/,
    init        => sub { $started{"$_[1]:$_[2]"}++ };

subtest 'before preload' => sub {
    is silo->quux, 42, 'unconditional resource';
    is_deeply \%started, {}, 'no preload called = empty';
};

subtest 'after preload' => sub {
    silo->ctl->preload;
    is_deeply \%started,
        { foo => 1, "with_args:first" => 1, "with_args:last" => 1 },
        'preload called = preloaded';
};

done_testing;
