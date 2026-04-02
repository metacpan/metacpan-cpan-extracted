#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# === Child overrides parent slot spec ===

Object::Proto::define('BaseConfig',
    'name:Str:required',
    'value:Str:default(none)',
    'priority:Int:default(0)',
);

# Child overrides 'value' to be Int with different default
# and overrides 'priority' to be required
Object::Proto::define('StrictConfig',
    extends => 'BaseConfig',
    'value:Int:default(42)',
    'extra:Str',
);

# Check properties exist
my @props = sort(Object::Proto::properties('StrictConfig'));
is_deeply(\@props, [qw(extra name priority value)], 'overridden class has correct properties');

# Override should use child spec
my $cfg = new StrictConfig name => 'test', extra => 'bonus';
is($cfg->value, 42, 'overridden default applies');
is($cfg->priority, 0, 'non-overridden parent default still works');
is($cfg->extra, 'bonus', 'own property works');

# Overridden slot info reflects child spec
my $info = Object::Proto::slot_info('StrictConfig', 'value');
ok($info, 'slot_info for overridden property');
is($info->{has_type}, 1, 'overridden property has type');
is($info->{has_default}, 1, 'overridden property has default');

done_testing;
