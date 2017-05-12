use v5.14;
use strict;
use warnings;
no warnings 'qw'; # separating words with commas
use autodie;
use Test::More 0.92;
use Test::Deep 0.110 qw/cmp_deeply/;
use Storable qw/dclone/;

use lib 't/lib';
use TestHelper;
use JSON;

my %templates = (
  node => {
    chef_environment => '_default',
    run_list         => [],
  },
  role => {
    json_class          => "Chef::Role",
    chef_type           => "role",
    run_list            => [],
    env_run_lists       => {},
    default_attributes  => {},
    override_attributes => {},
  },
  environment => {
    json_class          => "Chef::Environment",
    chef_type           => "environment",
    default_attributes  => {},
    override_attributes => {},
  },
);

my @recipe_role_subtests = (
  {
    label    => "strip recipe",
    apply    => [qw/-r nginx/],
    strip    => [qw/-r nginx/],
    expected => {},
  },
  {
    label    => "strip only one recipe",
    apply    => [qw/-r nginx -r postfix/],
    strip    => [qw/-r nginx/],
    expected => {
      run_list => [qw/recipe[postfix]/],
    },
  },
  {
    label    => "strip role",
    apply    => [qw/-R web/],
    strip    => [qw/-R web/],
    expected => {},
  },
  {
    label    => "strip only one role",
    apply    => [qw/-R web -R mail/],
    strip    => [qw/-R web/],
    expected => {
      run_list => [qw/role[mail]/],
    },
  },
  {
    label    => "strip only role of mixed roles/recipes",
    apply    => [qw/-R web -r postfix/],
    strip    => [qw/-R web/],
    expected => {
      run_list => [qw/recipe[postfix]/],
    },
  },
);

my @flat_attribute_subtests = (
  {
    label    => "strip attribute",
    apply    => [qw/-d nginx.port=80/],
    strip    => [qw/-d nginx.port/],
    expected => {},
  },
  {
    label    => "strip only one attribute",
    apply    => [qw/-d nginx.port=80 -d nginx.user=nobody/],
    strip    => [qw/-d nginx.user/],
    expected => {
      nginx => { port => 80 }
    },
  },
  {
    label    => "strip entire attribute hash shoudn't work",
    apply    => [qw/-d nginx.port=80 -d nginx.user=nobody/],
    strip    => [qw/-d nginx/],
    expected => {
      nginx => {
        port => 80,
        user => 'nobody',
      },
    },
  },
  {
    label    => "strip attribute with useless value",
    apply    => [qw/-d nginx.port=80/],
    strip    => [qw/-d nginx.port=8080/],
    expected => {},
  },
  {
    label    => "strip attribute list",
    apply    => [qw/-d nginx.port=80,8080/],
    strip    => [qw/-d nginx.port/],
    expected => {},
  },
  {
    label    => "strip escaped attribute",
    apply    => [qw/-d nginx\.port=80/],
    strip    => [qw/-d nginx\.port/],
    expected => {},
  },
);

my @deep_attribute_subtests = (
  {
    label    => "strip default attribute",
    apply    => [qw/-d nginx.port=80/],
    strip    => [qw/-d nginx.port/],
    expected => {},
  },
  {
    label    => "strip override attribute",
    apply    => [qw/--override nginx.port=80/],
    strip    => [qw/--override nginx.port/],
    expected => {},
  },
  {
    label    => "strip only one attribute",
    apply    => [qw/-d nginx.port=80 -d nginx.user=nobody/],
    strip    => [qw/-d nginx.user/],
    expected => {
      default_attributes => {
        nginx => { port => 80 },
      },
    },
  },
  {
    label    => "strip only one attribute default/override",
    apply    => [qw/-d nginx.port=80 --override nginx.user=nobody/],
    strip    => [qw/--override nginx.user/],
    expected => {
      default_attributes => {
        nginx => { port => 80 },
      },
    },
  },
  {
    label    => "strip entire attribute hash shoudn't work",
    apply    => [qw/-d nginx.port=80 -d nginx.user=nobody/],
    strip    => [qw/-d nginx/],
    expected => {
      default_attributes => {
        nginx => {
          port => 80,
          user => 'nobody',
        },
      },
    },
  },
  {
    label    => "strip attribute with useless value",
    apply    => [qw/-d nginx.port=80/],
    strip    => [qw/-d nginx.port=8080/],
    expected => {},
  },
  {
    label    => "strip attribute list",
    apply    => [qw/-d nginx.port=80,8080/],
    strip    => [qw/-d nginx.port/],
    expected => {},
  },
  {
    label    => "strip escaped attribute",
    apply    => [qw/-d nginx\.port=80/],
    strip    => [qw/-d nginx\.port/],
    expected => {},
  },
);

my @env_run_list_subtests = (
  {
    label    => "env_run_lists: strip recipe",
    apply    => [qw/-r nginx -E test/],
    strip    => [qw/-r nginx -E test/],
    expected => {},
  },
  {
    label    => "env_run_lists: strip only one recipe",
    apply    => [qw/-r nginx -r postfix -E test/],
    strip    => [qw/-r nginx -E test/],
    expected => {
      env_run_lists => {
        test => [qw/recipe[postfix]/],
      },
    },
  },
  {
    label    => "env_run_lists: strip role",
    apply    => [qw/-R web -E test/],
    strip    => [qw/-R web -E test/],
    expected => {},
  },
  {
    label    => "env_run_lists: strip only one role",
    apply    => [qw/-R web -R mail -E test/],
    strip    => [qw/-R web -E test/],
    expected => {
      env_run_lists => {
        test => [qw/role[mail]/]
      },
    },
  },
  {
    label    => "env_run_lists: strip only role of mixed roles/recipes",
    apply    => [qw/-R web -r postfix -E test/],
    strip    => [qw/-R web -E test/],
    expected => {
      env_run_lists => {
        test => [qw/recipe[postfix]/],
      },
    },
  },
);

my @cases = (
  {
    type => "node",
    name => 'foo.example.com',
    new  => sub { my ( $p, $n ) = @_; $p->node($n) },
    subtests => [ @recipe_role_subtests, @flat_attribute_subtests ],
  },
  {
    type     => "node",
    name     => 'foo.example.com',
    new      => sub { my ( $p, $n ) = @_; $p->node( $n, { env => 'test' } ) },
    env_args => [qw/-E test/],
    subtests => [ @recipe_role_subtests, @flat_attribute_subtests ],
  },
  {
    type => "role",
    name => 'web',
    new  => sub { my ( $p, $n ) = @_; $p->role($n) },
    subtests => [ @recipe_role_subtests, @deep_attribute_subtests, @env_run_list_subtests ],
  },
  {
    type     => "environment",
    name     => 'test',
    new      => sub { my ( $p, $n ) = @_; $p->environment($n) },
    subtests => [@deep_attribute_subtests],
  },
  {
    type     => "bag",
    name     => 'user/xdg',
    new      => sub { my ( $p, $n ) = @_; $p->bag($n) },
    subtests => [ @flat_attribute_subtests ],
  },
);

for my $c (@cases) {
  for my $st ( @{ $c->{subtests} } ) {
    my $env = exists( $c->{env_args} ) ? " (@{$c->{env_args}})" : "";
    subtest "$c->{type} $st->{label}$env" => sub {
      my ( $wd, $pantry ) = _create_pantry();
      my $obj = $c->{new}->( $pantry, $c->{name} );

      _try_command( 'create', $c->{type}, $c->{name}, @{ $c->{env_args} || [] } );
      _try_command(
        'apply', $c->{type}, $c->{name}, @{ $st->{apply} },
        @{ $c->{env_args} || [] }
      );
      _try_command(
        'strip', $c->{type}, $c->{name}, @{ $st->{strip} },
        @{ $c->{env_args} || [] }
      );

      my $data     = _thaw_file( $obj->path );
      my $expected = dclone $st->{expected};
      my $id_field = $c->{type} eq 'bag' ? 'id' : 'name';
      my ($first, $last) = split "/", $c->{name};
      $last //= $first;
      $expected->{$id_field} //= $last;
      for my $k ( keys %{ $templates{ $c->{type} } } ) {
        $expected->{$k} //= $templates{ $c->{type} }{$k};
      }
      if ( $c->{env_args} ) {
        $expected->{chef_environment} = $c->{env_args}[-1];
      }

      cmp_deeply( $data, $expected, "data file correct" )
        or diag explain $data;
    };
  }
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
