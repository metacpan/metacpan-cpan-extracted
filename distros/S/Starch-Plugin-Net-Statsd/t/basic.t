#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;
use Test::Starch;
use Starch;
use Net::Statsd;
use Package::Stash;

Test::Starch->new(
    plugins => ['::Net::Statsd'],
)->test();

my $stash = Package::Stash->new('Net::Statsd');
my @sends;
$stash->add_symbol(
    '&send',
    sub{ push @sends, [@_] },
);

my $starch = Starch->new(
    plugins => ['::Net::Statsd'],
    store => {
        class => '::Layered',
        outer => {
            class => '::Memory',
            statsd_path => 'outer',
        },
        inner => {
            class => '::Memory',
        },
    },
);

my $store = $starch->store();

$store->get('foobar', []);
is_deeply(
    \@sends,
    [
        [{ 'starch.outer.get-miss' => '0|ms' }, 1],
        [{ 'starch.Memory.get-miss' => '0|ms' }, 1],
    ],
    'get-miss',
);
@sends = ();

$store->inner->set('foobar', [], {'test'=>1});
is_deeply(
    \@sends,
    [
        [{ 'starch.Memory.set' => '0|ms' }, 1],
    ],
    'set',
);
@sends = ();

$store->get('foobar', []);
is_deeply(
    \@sends,
    [
        [{ 'starch.outer.get-miss' => '0|ms' }, 1],
        [{ 'starch.Memory.get-hit' => '0|ms' }, 1],
        [{ 'starch.outer.set' => '0|ms' }, 1],
    ],
    'get-hit',
);
@sends = ();

$store->remove('foobar', []);
is_deeply(
    \@sends,
    [
        [{ 'starch.outer.remove' => '0|ms' }, 1],
        [{ 'starch.Memory.remove' => '0|ms' }, 1],
    ],
    'remove',
);
@sends = ();

{
    package Test::Starch::Store::Fail;
    use Moo;
    with 'Starch::Store';
    sub set { die 'set_fail' }
    sub get { die 'get_fail' }
    sub remove { die 'remove_fail' }
}

$starch = Starch->new(
    plugins => ['::Net::Statsd'],
    store => {
        class => 'Test::Starch::Store::Fail',
        statsd_path => 'fail',
    },
    statsd_root_path => 'blah',
    statsd_sample_rate => 1,
);

$store = $starch->store();

like(
    exception { $store->set('foobar', [], {test=>1}) },
    qr{set_fail},
    'set failed',
);
is_deeply(
    \@sends,
    [
        [{ 'blah.fail.set-error' => '0|ms' }, 1],
    ],
    'set-error',
);
@sends = ();

like(
    exception { $store->get('foobar', []) },
    qr{get_fail},
    'get failed',
);
is_deeply(
    \@sends,
    [
        [{ 'blah.fail.get-error' => '0|ms' }, 1],
    ],
    'get-error',
);
@sends = ();

like(
    exception { $store->remove('foobar', []) },
    qr{remove_fail},
    'remove failed',
);
is_deeply(
    \@sends,
    [
        [{ 'blah.fail.remove-error' => '0|ms' }, 1],
    ],
    'remove-error',
);
@sends = ();

done_testing();
