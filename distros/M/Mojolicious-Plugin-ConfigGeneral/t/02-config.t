#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;
use Test::Mojo;

# The Lite scenario
use Mojolicious::Lite;

# Load plugin
plugin ConfigGeneral => {file => 't/test.conf'};

# Create test application
my $t = Test::Mojo->new;

# Loaded config data
is($t->app->config('_config_loaded'), 1, 'Parse config correctly');

# Get on/off flags
is($t->app->config('baz'), 1, 'Get on/off flags');

# Get by pointer path
is($t->app->conf->get('/box/test'), 123, 'Get by pointer path');

# Get first value
is($t->app->conf->first('/array/test'), 'First', 'Get first value');

# Get latest value
is($t->app->conf->latest('/array/test'), 'Third', 'Get latest value');

# Get list of values as array
is(ref($t->app->conf->array('/array/test')), 'ARRAY', 'Get list of values as array');

# Get hash of values
is(ref($t->app->conf->hash('/array')), 'HASH', 'Get hash of values');
#diag explain $t->app->conf->hash('/array');

#diag explain $t->app->config;

done_testing;

1;

__END__
