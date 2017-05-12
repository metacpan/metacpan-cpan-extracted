use v5.14;
use strict;
use warnings;
use autodie;
use Test::More 0.92;

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
    name => 'foo.example.com',
    args => [qw/-E test/],
    new => sub { my ($p,$n) = @_; $p->node($n, {env => 'test'}) },
  },
  {
    label => "role",
    type => "role",
    name => 'web',
    new => sub { my ($p,$n) = @_; $p->role($n) },
  },
  {
    label => "environment",
    type => "environment",
    name => 'test',
    new => sub { my ($p,$n) = @_; $p->environment($n) },
  },
  {
    label => "bag",
    type => "bag",
    name => 'user/xdg',
    new_name => 'oldusers/xdg',
    new => sub { my ($p,$n) = @_; $p->bag($n) },
  },
);

local $ENV{PERL_MM_USE_DEFAULT} = 1;

for my $c ( @cases ) {
  my $new_name = $c->{new_name} // 'renamed';
  subtest "$c->{label}: rename" => sub {
    my ($wd, $pantry) = _create_pantry();
    my $obj = $c->{new}->($pantry, $c->{name});
    my $new = $c->{new}->($pantry, $new_name);
    _try_command('create', $c->{type}, $c->{name}, @{$c->{args}||[]});
    _try_command('rename', $c->{type}, $c->{name}, $new_name, @{$c->{args}||[]});
    ok( ! -e $obj->path, "original object is gone" );
    ok( -e $new->path, "renamed object exists" );
  };

  subtest "$c->{label}: rename missing" => sub {
    my ($wd, $pantry) = _create_pantry();
    my $obj = $c->{new}->($pantry, $c->{name});
    my $new = $c->{new}->($pantry, $new_name);
    my $result = _try_command('rename', $c->{type}, $c->{name}, $new_name, @{$c->{args}||[]}, { exit_code => -1});
    like( $result->error, qr/does not exist/, "error message" );
    ok( ! -e $obj->path, "original object not there" );
    ok( ! -e $new->path, "renamed object not there" );
  };

  subtest "$c->{label}: rename won't clobber" => sub {
    my ($wd, $pantry) = _create_pantry();
    my $obj = $c->{new}->($pantry, $c->{name});
    my $new = $c->{new}->($pantry, $new_name);
    _try_command('create', $c->{type}, $c->{name}, @{$c->{args}||[]});
    _try_command('create', $c->{type}, $new_name, @{$c->{args}||[]});
    my $result = _try_command('rename', $c->{type}, $c->{name}, $new_name, @{$c->{args}||[]}, { exit_code => -1});
    like( $result->error, qr/already exists/, "error message" );
    ok( -e $obj->path, "original object is there" );
    ok( -e $new->path, "existing object is there" );
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
