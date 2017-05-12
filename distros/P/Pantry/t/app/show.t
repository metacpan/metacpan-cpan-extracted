use v5.14;
use strict;
use warnings;
use autodie;
use Test::More 0.92;

use lib 't/lib';
use TestHelper;
use JSON;

my @cases = (
  {
    label => "node",
    type => "node",
    name => 'foo.example.com',
    new => sub { my ($p,$n) = @_; $p->node($n) },
    args => [qw/-r nginx -d nginx.port=80/],
    expected => {
      run_list => [ 'recipe[nginx]' ],
      chef_environment => '_default',
      nginx => {
        port => 80
      },
    },
  },
  {
    label => "node in test env",
    type => "node",
    name => 'foo.example.com',
    new => sub { my ($p,$n) = @_; $p->node($n, {env => 'test'}) },
    args => [qw/-r nginx -d nginx.port=80/],
    env_args => [qw/--env test/],
    expected => {
      run_list => [ 'recipe[nginx]' ],
      chef_environment => 'test',
      nginx => {
        port => 80
      },
    },
  },
  {
    label => "role",
    type => "role",
    name => 'web',
    new => sub { my ($p,$n) = @_; $p->role($n) },
    args => [qw/-r nginx -d nginx.port=80/],
    expected => {
      json_class => "Chef::Role",
      chef_type => "role",
      run_list => [ 'recipe[nginx]' ],
      env_run_lists       => {},
      default_attributes => {
        nginx => {
          port => 80
        },
      },
      override_attributes => {},
    },
  },
  {
    label => "environment",
    type => "environment",
    name => 'web',
    new => sub { my ($p,$n) = @_; $p->environment($n) },
    args => [qw/-d nginx.port=80/],
    expected => {
      json_class => "Chef::Environment",
      chef_type => "environment",
      default_attributes => {
        nginx => {
          port => 80
        },
      },
      override_attributes => {},
    },
  },
  {
    label => "bag",
    type => "bag",
    name => 'xdg',
    new => sub { my ($p,$n) = @_; $p->bag($n) },
    args => [qw(-d shell=/bin/bash)],
    expected => {
      shell => '/bin/bash',
    },
  },
  {
    label => "bag with subdir",
    type => "bag",
    name => 'users/xdg',
    new => sub { my ($p,$n) = @_; $p->bag($n) },
    args => [qw(-d shell=/bin/bash)],
    expected => {
      shell => '/bin/bash',
    },
  },
);

for my $c ( @cases ) {
  subtest "$c->{type}: show" => sub {
    my ($wd, $pantry) = _create_pantry();
    my $obj = $c->{new}->($pantry, $c->{name});

    _try_command('create', $c->{type}, $c->{name}, @{ $c->{env_args} });
    _try_command('apply', $c->{type}, $c->{name}, @{ $c->{args} });

    my $result = _try_command('show', $c->{type}, $c->{name});
    my $data = eval { decode_json( $result->output ) };

    my $id_field = $c->{type} eq 'bag' ? 'id' : 'name';
    my ($first, $last) = split "/", $c->{name};
    $last //= $first;
    is ( delete $data->{$id_field}, $last, "$id_field correct in output JSON" );

    is_deeply( $data, $c->{expected}, "remaining fields correct in output JSON" )
      or diag $result->output;
  };

  subtest "$c->{type}: show invalid" => sub {
    my ($wd, $pantry) = _create_pantry();
    my $obj = $c->{new}->($pantry, $c->{name});

    ok( ! -e $obj->path, "$c->{type} '$c->{name}' not created yet" );

    my $result = _try_command('show', $c->{type}, $c->{name}, { exit_code => "-1" });
    like( $result->error, qr/does not exist/i,
      "showing invalid $c->{type} gives error message"
    ) or diag $result->error;
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
