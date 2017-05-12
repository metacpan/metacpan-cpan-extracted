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
  bag => {
  },
);

my @recipe_role_subtests = (
  {
    argv     => [qw/-r nginx/],
    expected => {
      run_list => ['recipe[nginx]'],
    },
  },
  {
    argv     => [qw/-R web/],
    expected => {
      run_list => ['role[web]'],
    },
  },
  {
    argv     => [qw/-r postfix -r iptables -R web/],
    expected => {
      run_list => [qw/role[web] recipe[postfix] recipe[iptables]/],
    },
  },
);

my @flat_attribute_subtests = (
  {
    argv     => [qw/-d nginx.port=80/],
    expected => {
      run_list => [],
      nginx    => { port => 80 },
    },
  },
  {
    argv     => [qw/-d nginx.port=80,8080/],
    expected => {
      run_list => [],
      nginx    => { port => [ 80, 8080 ] },
    },
  },
  {
    argv     => [qw/-d nginx\.port=80,8000\,8080/],
    expected => {
      run_list     => [],
      'nginx.port' => [ 80, '8000,8080' ],
    },
  },
  {
    argv     => [qw/-d nginx\.enable=false/],
    expected => {
      run_list       => [],
      'nginx.enable' => JSON::false,
    },
  },
  {
    argv     => [qw/-d nginx\.enable=true/],
    expected => {
      run_list       => [],
      'nginx.enable' => JSON::true,
    },
  },
);

my @deep_attribute_subtests = (
  {
    argv     => [qw/-d nginx.port=80/],
    expected => {
      default_attributes => {
        nginx => { port => 80 },
      },
    },
  },
  {
    argv     => [qw/--override nginx.port=80/],
    expected => {
      override_attributes => {
        nginx => { port => 80 },
      },
    },
  },
  {
    argv     => [qw/-d nginx.port=80,8080/],
    expected => {
      default_attributes => {
        nginx => { port => [ 80, 8080 ] },
      },
    },
  },
  {
    argv     => [qw/-d nginx\.port=80,8000\,8080/],
    expected => {
      default_attributes => {
        'nginx.port' => [ 80, '8000,8080' ],
      },
    },
  },
  {
    argv     => [qw/-d nginx\.enable=false/],
    expected => {
      default_attributes => {
        'nginx.enable' => JSON::false,
      }
    },
  },
  {
    argv     => [qw/-d nginx\.enable=true/],
    expected => {
      default_attributes => {
        'nginx.enable' => JSON::true,
      }
    },
  },
);

my @bag_attribute_subtests = (
  {
    argv     => [qw/-d nginx.port=80/],
    expected => {
      nginx    => { port => 80 },
    },
  },
  {
    argv     => [qw/-d nginx.port=80,8080/],
    expected => {
      nginx    => { port => [ 80, 8080 ] },
    },
  },
  {
    argv     => [qw/-d nginx\.port=80,8000\,8080/],
    expected => {
      'nginx.port' => [ 80, '8000,8080' ],
    },
  },
  {
    argv     => [qw/-d nginx\.enable=false/],
    expected => {
      'nginx.enable' => JSON::false,
    },
  },
  {
    argv     => [qw/-d nginx\.enable=true/],
    expected => {
      'nginx.enable' => JSON::true,
    },
  },
);

my @env_run_list_subtests = (
  {
    argv     => [qw/-r nginx -E test/],
    expected => {
      env_run_lists => {
        test => ['recipe[nginx]'],
      },
    },
  },
  {
    argv     => [qw/-R web -E test/],
    expected => {
      env_run_lists => {
        test =>  ['role[web]'],
      },
    },
  },
  {
    argv     => [qw/-r postfix -r iptables -R web -E test/],
    expected => {
      env_run_lists => {
        test => [qw/role[web] recipe[postfix] recipe[iptables]/],
      }
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
    subtests => [ @recipe_role_subtests, @env_run_list_subtests, @deep_attribute_subtests ],
  },

  {
    type => "environment",
    name => 'test',
    new  => sub { my ( $p, $n ) = @_; $p->environment($n) },
    subtests => [ @deep_attribute_subtests ],
  },

  {
    type => "bag",
    name => 'user/xdg',
    new  => sub { my ( $p, $n ) = @_; $p->bag($n) },
    subtests => [ @bag_attribute_subtests ],
  },
);

for my $c (@cases) {
  for my $st ( @{ $c->{subtests} } ) {
    my @argv = @{ $st->{argv} };
    push @argv, @{ $c->{env_args} } if exists $c->{env_args};
    subtest "$c->{type} NAME @argv" => sub {
      my ( $wd, $pantry ) = _create_pantry();
      my $obj = $c->{new}->( $pantry, $c->{name} );

      _try_command( 'create', $c->{type}, $c->{name}, @{ $c->{env_args} || [] } );
      _try_command( 'apply', $c->{type}, $c->{name}, @argv );

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
