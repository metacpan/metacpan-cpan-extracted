#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok('Prancer::Config');

{
    my $config = Prancer::Config->load('t/configs/single.yml');

    ok($config);
    ok(ref($config));
    is(ref($config), 'Prancer::Config');
    ok($config->has('foo'));

    my $a = $config->get('foo');
    is($a, 'bar');

    my $b = $config->get('listings');
    ok(ref($b));
    is(ref($b), 'ARRAY');
    is(scalar(@{$b}), 3);
    is_deeply($b, [ 'a', 'b', 'c' ]);

    my @c = $config->get('listings');
    is(scalar(@c), 3);
    is_deeply(\@c, [ 'a', 'b', 'c' ]);

    my @d = $config->get('foo');
    is(scalar(@d), 1);
    is_deeply(\@d, [ 'bar' ]);

    my $e = $config->get('asdf');
    ok(!defined($e));

    my @f = $config->get('asdf');
    is(scalar(@f), 0);

    my $g = $config->get('channels');
    ok(ref($g));
    is(ref($g), 'HASH');
    is_deeply($g, { 'foo' => 'bar', 'baz' => 'bat' });

    my %h = $config->get('channels');
    is_deeply(\%h, { 'foo' => 'bar', 'baz' => 'bat' });

    # test default values
    my $i = $config->get('asdf', 'fdsa');
    is($i, 'fdsa');

    my $j = $config->get('asdf', [ 'asdf', 'fdsa' ]);
    ok(ref($j));
    is(ref($j), 'ARRAY');
    is(scalar(@{$j}), 2);
    is_deeply($j, [ 'asdf', 'fdsa' ]);

    my @k = $config->get('asdf', [ 'asdf', 'fdsa' ]);
    is(scalar(@k), 2);
    is_deeply(\@k, [ 'asdf', 'fdsa' ]);
}

# test setting values
{
    # test setting value that doesn't exist
    {
        my $config = Prancer::Config->load('t/configs/single.yml');
        ok(!$config->has('qwerty'));
        ok(!defined($config->get('qwerty')));
        my $a = $config->set('qwerty', 'ytrewq');
        ok(!defined($a));
        ok($config->has('qwerty'));
        is($config->get('qwerty'), 'ytrewq');
    }

    # test setting a value over another value
    {
        my $config = Prancer::Config->load('t/configs/single.yml');
        is($config->get('foo'), 'bar');
        my $a = $config->set('foo', 'bazbat');
        is($a, 'bar');
        is($config->get('foo'), 'bazbat');
    }

    # test setting a value over a complex value and getting a reference
    {
        my $config = Prancer::Config->load('t/configs/single.yml');
        my $a = $config->set('listings', 'qwerty');
        ok(ref($a));
        is(ref($a), 'ARRAY');
        is_deeply($a, [ 'a', 'b', 'c' ]);
        my $b = $config->get('listings');
        is($b, 'qwerty');
    }

    # test setting a value over a complex value and getting a non-reference
    {
        my $config = Prancer::Config->load('t/configs/single.yml');
        my @a = $config->set('listings', 'qwerty');
        ok(scalar(@a));
        is(scalar(@a), 3);
        is_deeply(\@a, [ 'a', 'b', 'c' ]);
        my $b = $config->get('listings');
        is($b, 'qwerty');
    }
}

# test removing values
{
    # test removing a value that doesn't exist
    {
        my $config = Prancer::Config->load('t/configs/single.yml');
        my $a = $config->get('qwerty');
        ok(!defined($a));
        $config->remove('qwerty');
        ok(!defined($config->get('qwerty')));
    }

    # test removing a value
    {
        my $config = Prancer::Config->load('t/configs/single.yml');
        my $a = $config->get('foo');
        is($a, 'bar');
        $config->remove('foo');
        ok(!defined($config->get('foo')));
    }

    # test removing a complex value and getting a reference
    {
        my $config = Prancer::Config->load('t/configs/single.yml');
        my $a = $config->remove('listings');
        ok(ref($a));
        is(ref($a), 'ARRAY');
        is_deeply($a, [ 'a', 'b', 'c' ]);
        my $b = $config->get('listings');
        ok(!defined($b));
    }

    # test setting a value over a complex value and getting a non-reference
    {
        my $config = Prancer::Config->load('t/configs/single.yml');
        my @a = $config->remove('listings');
        ok(scalar(@a));
        is(scalar(@a), 3);
        is_deeply(\@a, [ 'a', 'b', 'c' ]);
        my $b = $config->get('listings');
        ok(!defined($b));
    }
}

# test against using environment variables to load from directories
{
    {
        delete(local $ENV{'ENVIRONMENT'});
        my $config = Prancer::Config->load('t/configs/envs');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        is($config->get('foo'), 'barbazbat');
        is($config->get('name'), 'development-config-file');
    }

    {
        local $ENV{'ENVIRONMENT'} = 'development';
        my $config = Prancer::Config->load('t/configs/envs');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        is($config->get('foo'), 'barbazbat');
        is($config->get('name'), 'development-config-file');
    }

    {
        local $ENV{'ENVIRONMENT'} = 'production';
        my $config = Prancer::Config->load('t/configs/envs');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        is($config->get('foo'), 'barbazbat');
        is($config->get('name'), 'production-config-file');
    }
}

# test against situations where there are no environment config files
{
    {
        delete(local $ENV{'ENVIRONMENT'});
        my $config = Prancer::Config->load('t/configs/missing');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        is($config->get('foo'), 'qwerty');
        is($config->get('name'), 'config');
    }

    {
        local $ENV{'ENVIRONMENT'} = 'development';
        my $config = Prancer::Config->load('t/configs/missing');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        is($config->get('foo'), 'qwerty');
        is($config->get('name'), 'config');
    }

    {
        local $ENV{'ENVIRONMENT'} = 'production';
        my $config = Prancer::Config->load('t/configs/missing');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        is($config->get('foo'), 'qwerty');
        is($config->get('name'), 'config');
    }
}

# test against empty directories
{
    {
        delete(local $ENV{'ENVIRONMENT'});
        my $config = Prancer::Config->load('t/configs/empty');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        ok(!defined($config->get('foo')));
        ok(!defined($config->get('name')));
    }

    {
        local $ENV{'ENVIRONMENT'} = 'development';
        my $config = Prancer::Config->load('t/configs/empty');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        ok(!defined($config->get('foo')));
        ok(!defined($config->get('name')));
    }

    {
        local $ENV{'ENVIRONMENT'} = 'production';
        my $config = Prancer::Config->load('t/configs/empty');
        ok($config);
        ok(ref($config));
        is(ref($config), 'Prancer::Config');
        ok(!defined($config->get('foo')));
        ok(!defined($config->get('name')));
    }
}

done_testing();
