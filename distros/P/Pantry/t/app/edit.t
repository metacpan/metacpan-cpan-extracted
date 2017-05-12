use v5.14;
use strict;
use warnings;
use autodie;
use Test::More 0.92;

# establish placeholder for later localization
BEGIN { *CORE::GLOBAL::system = sub { CORE::system(@_) } }

use lib 't/lib';
use TestHelper;

my @cases = (
  {
    label => "node",
    type => "node",
    name => 'foo.example.com',
    new => sub { my ($p,$n) = @_; $p->node($n) },
  },
  {
    label => "node in test env",
    type => "node",
    args => [qw/-E test/],
    name => 'foo.example.com',
    new => sub { my ($p,$n) = @_; $p->node($n, {env => 'test'}) },
  },
  {
    label => "environment",
    type => "environment",
    name => 'test',
    new => sub { my ($p,$n) = @_; $p->environment($n) },
  },
  {
    label => "role",
    type => "role",
    name => 'web',
    new => sub { my ($p,$n) = @_; $p->role($n) },
  },
  {
    label => "bag",
    type => "bag",
    name => 'user/xdg',
    new => sub { my ($p,$n) = @_; $p->bag($n) },
  },
);

for my $c ( @cases ) {
  subtest "edit $c->{type}" => sub {
    my ($wd, $pantry) = _create_pantry();
    my $obj = $c->{new}->($pantry, $c->{name});
    my @cli_args = @{$c->{args} || []};

    _try_command('create', $c->{type}, $c->{name}, @cli_args);
    ok( -e $obj->path, "node file created" );

    {
      my @args = ('');
      no warnings 'redefine';
      local *CORE::GLOBAL::system = sub { @args = @_; return 0 };
      local $ENV{EDITOR} = "perl -e exit";
      my $result = _try_command('edit', $c->{type}, $c->{name});
      is( $args[-1], $obj->path, "(fake) editor invoked" );
    }
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
