#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/../lib";
use Mojolicious::Plugin::Fondation::Utils qw(merge);

# =========================================================================
# Scalar merge -- highest priority wins (direct > app_conf > defaults)
# =========================================================================

subtest 'Scalars: direct overrides app_conf overrides defaults' => sub {
    my $result = merge(
        { key => 'direct' },
        { key => 'app' },
        { key => 'default' },
    );
    is($result->{key}, 'direct', 'direct wins over app_conf and defaults');
};

subtest 'Scalars: app_conf used when no direct' => sub {
    my $result = merge(
        {},
        { key => 'app' },
        { key => 'default' },
    );
    is($result->{key}, 'app', 'app_conf wins when no direct');
};

subtest 'Scalars: defaults used when no direct or app_conf' => sub {
    my $result = merge(
        {},
        {},
        { key => 'default' },
    );
    is($result->{key}, 'default', 'defaults used when nothing else provided');
};

# =========================================================================
# Hash merge -- recursive, priority on conflicting keys
# =========================================================================

subtest 'Hashes: merged recursively' => sub {
    my $result = merge(
        { nested => { b => 2 } },
        { nested => { a => 1 } },
        { nested => { x => 0, a => 0 } },
    );
    is($result->{nested}{a}, 1, 'app_conf overrides defaults for nested.a');
    is($result->{nested}{b}, 2, 'direct overrides everything for nested.b');
    is($result->{nested}{x}, 0, 'defaults key survives when not overridden');
};

subtest 'Hashes: direct empty hash does not wipe' => sub {
    my $result = merge(
        { nested => {} },
        {},
        { nested => { a => 1, b => 2 } },
    );
    is($result->{nested}{a}, 1, 'empty direct hash keeps defaults');
    is($result->{nested}{b}, 2, 'empty direct hash keeps all defaults');
};

# =========================================================================
# Array merge -- concatenated, left-to-right in priority order
# =========================================================================

subtest 'Arrays: concatenated from all levels' => sub {
    my $result = merge(
        { tags => ['c'] },
        { tags => ['b'] },
        { tags => ['a'] },
    );
    # Priority order: direct( c ) + app_conf( b ) + defaults( a ) → c,b,a
    is_deeply($result->{tags}, ['c', 'b', 'a'], 'arrays concatenated in priority order');
};

subtest 'Arrays: partial config -- only defaults and direct' => sub {
    my $result = merge(
        { roles => ['admin'] },
        {},
        { roles => ['user'] },
    );
    is_deeply($result->{roles}, ['admin', 'user'], 'direct + defaults concatenated');
};

subtest 'Arrays: empty arrays do not pollute' => sub {
    my $result = merge(
        { tags => [] },
        { tags => ['b'] },
        { tags => [] },
    );
    is_deeply($result->{tags}, ['b'], 'empty arrays do not add elements');
};

subtest 'Arrays: all empty' => sub {
    my $result = merge(
        { tags => [] },
        { tags => [] },
        { tags => [] },
    );
    is_deeply($result->{tags}, [], 'all empty arrays → empty');
};

# =========================================================================
# Mixed: hashes containing arrays, arrays of hashes, etc.
# =========================================================================

subtest 'Mixed: hash with nested arrays at multiple levels' => sub {
    my $result = merge(
        { plugin => { allowed_roles => ['admin'] } },
        { plugin => { allowed_roles => ['editor'] } },
        { plugin => { allowed_roles => ['user'] } },
    );
    is_deeply(
        $result->{plugin}{allowed_roles},
        ['admin', 'editor', 'user'],
        'nested arrays concatenated (direct, app, defaults)'
    );
};

subtest 'Mixed: different keys across levels' => sub {
    my $result = merge(
        { direct_only  => [3] },
        { app_only     => [2], shared => ['b'] },
        { default_only => [1], shared => ['a'] },
    );
    is_deeply($result->{direct_only},  [3],       'direct-only array preserved');
    is_deeply($result->{app_only},     [2],       'app-only array preserved');
    is_deeply($result->{default_only}, [1],       'default-only array preserved');
    is_deeply($result->{shared},       ['b', 'a'], 'shared array concatenated (app, defaults)');
};

# =========================================================================
# Undef handling
# =========================================================================

subtest 'Undef: missing levels' => sub {
    my $result = merge(
        undef,
        { key => 'app' },
        { key => 'default' },
    );
    is($result->{key}, 'app', 'undef direct falls through to app_conf');
};

subtest 'Undef: all undef' => sub {
    my $result = merge(undef, undef, undef);
    is_deeply($result, {}, 'all undef → empty hashref');
};

# =========================================================================
# Typical Fondation use-cases
# =========================================================================

subtest 'Use case: plugin tags accumulate across config levels' => sub {
    # Plugin defaults:   { tags => ['beta'] }
    # App config:        { tags => ['stable'] }
    # Direct dependency: { tags => ['experimental'] }
    my $result = merge(
        { tags => ['experimental'] },    # direct
        { tags => ['stable'] },          # app_conf (myapp.conf)
        { tags => ['beta'] },            # plugin defaults
    );
    is_deeply(
        $result->{tags},
        ['experimental', 'stable', 'beta'],
        'tags accumulate from all config levels (direct, app, defaults)'
    );
};

subtest 'Use case: dependencies are concatenated too' => sub {
    # This is the new behaviour: dependency lists merge like any other array.
    my $result = merge(
        { dependencies => ['Fondation::User'] },
        { dependencies => ['Fondation::Authorization'] },
        {},
    );
    ok(
        (grep { /User/ } @{$result->{dependencies}}),
        'User dependency present'
    );
    ok(
        (grep { /Authorization/ } @{$result->{dependencies}}),
        'Authorization dependency present (merged)'
    );
};

subtest 'Use case: overlapping scalars and arrays in plugin config' => sub {
    my $result = merge(
        { title => 'My App', roles => ['superadmin'] },
        { title => 'The App', roles => ['admin'] },
        { title => 'App', roles => ['user'] },
    );
    is($result->{title}, 'My App', 'scalar: direct wins');
    is_deeply($result->{roles}, ['superadmin', 'admin', 'user'], 'array: concatenated (direct, app, defaults)');
};

done_testing();
