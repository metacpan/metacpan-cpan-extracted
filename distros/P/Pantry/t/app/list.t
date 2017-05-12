use v5.14;
use strict;
use warnings;
use autodie;
use Test::More 0.92;
use Test::Deep 0.110 qw/cmp_deeply/;

use lib 't/lib';
use TestHelper;

my @cases = (
  {
    label => "nodes",
    type => "node",
    names => ['foo.example.com', 'bar.example.com'],
    new => sub { my ($p,$n) = @_; $p->node($n) },
  },
  {
    label => "nodes in specified environment",
    type => "node",
    args => [qw/-E test/],
    names => ['foo.example.com', 'bar.example.com'],
    new => sub { my ($p,$n) = @_; $p->node($n, {env => 'test'}) },
  },
  {
    label => "nodes in specified environment",
    type => "node",
    args => [qw/-E staging/],
    env_args => [qw/-E test/],
    names => ['foo.example.com', 'bar.example.com'],
    expected => [],
    new => sub { my ($p,$n) = @_; $p->node($n, {env => 'test'}) },
  },
  {
    label => "roles",
    type => "role",
    names => ['web', 'db'],
    new => sub { my ($p,$n) = @_; $p->role($n) },
  },
  {
    label => "environments",
    type => "environment",
    names => ['test', 'prod'],
    new => sub { my ($p,$n) = @_; $p->environment($n) },
  },
  {
    label => "bags",
    type => "bag",
    names => ['xdg', 'dag', 'users/egg'],
    new => sub { my ($p,$n) = @_; $p->bag($n) },
  },
);

for my $c ( @cases ) {
  subtest "list $c->{label}" => sub {
    my ($wd, $pantry) = _create_pantry();
    my @args = @{$c->{args} || []};
    my @env_args = @{($c->{env_args} ? $c->{env_args} : $c->{args}) || []};

    for my $name ( @{$c->{names}} ) {
      _try_command('create', $c->{type}, $name, @env_args);
    }

    my $result = _try_command('list', $c->{type}, @args);

    my $found = [sort split /\n/, $result->output];
    my $expected = $c->{expected} || $c->{names};
    cmp_deeply( $found, [ sort @$expected ], "saw expected list" )
      or diag "OUTPUT:\n" . $result->output;
  };
}

done_testing;
#
# This file is part of Pantry
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
