use v5.14;
use strict;
use warnings;
use autodie;
use Test::More 0.92;

use lib 't/lib';
use TestHelper;
use Path::Class;

my @cases = (
  {
    label => "node",
    type => "node",
    name => 'foo.example.com',
    new => sub { my ($p,$n) = @_; $p->node($n) },
    empty => {
      chef_environment => '_default',
      run_list => [],
    },
  },
  {
    label => "node with overrides",
    type => "node",
    name => 'foo.example.com',
    opts => [qw/--host localhost --port 2222 --user vagrant/],
    new => sub { my ($p,$n) = @_; $p->node($n) },
    empty => {
      run_list => [],
      chef_environment => '_default',
      pantry_host => 'localhost',
      pantry_port => 2222,
      pantry_user => 'vagrant',
    },
  },
  {
    label => "node in test environment",
    type => "node",
    name => 'foo.example.com',
    opts => [qw/-E test/],
    new => sub { my ($p,$n) = @_; $p->node($n, {env => 'test'}) },
    empty => {
      chef_environment => 'test',
      run_list => [],
    },
  },
  {
    label => "role",
    type => "role",
    name => 'web',
    new => sub { my ($p,$n) = @_; $p->role($n) },
    empty => {
      json_class => "Chef::Role",
      chef_type => "role",
      run_list => [],
      env_run_lists       => {},
      default_attributes => {},
      override_attributes => {},
    },
  },
  {
    label => "environment",
    type => "environment",
    name => 'test',
    new => sub { my ($p,$n) = @_; $p->environment($n) },
    empty => {
      json_class => "Chef::Environment",
      chef_type => "environment",
      default_attributes => {},
      override_attributes => {},
    },
  },
  {
    label => "cookbook",
    type => "cookbook",
    name => 'myapp',
    new => sub { my ($p,$n) = @_; $p->cookbook($n) },
    tree => {
      'README.rdoc' => undef,
      attributes    => { 'default.rb' => undef },
      definitions   => {},
      files         => {},
      libraries     => {},
      'metadata.rb' => undef,
      providers     => {},
      recipes       => { 'default.rb' => undef },
      resources     => {},
      templates     => { 'default' => {} },
    },
  },
  {
    label => "bag",
    type => "bag",
    name => 'xdg',
    new => sub { my ($p,$n) = @_; $p->bag($n) },
    empty => {},
  },
  {
    label => "bag with subdirectory",
    type => "bag",
    name => 'users/xdg',
    new => sub { my ($p,$n) = @_; $p->bag($n) },
    empty => {},
  },

);

for my $c ( @cases ) {
  subtest "create $c->{label}" => sub {
    my ($wd, $pantry) = _create_pantry();
    my $obj = $c->{new}->($pantry, $c->{name});

    ok( ! -e $obj->path, "$c->{type} '$c->{name}' not created yet" );

    _try_command('create', $c->{type}, $c->{name}, @{ $c->{opts} || [] });

    ok( -e $obj->path, "$c->{type} '$c->{name}' created" );

    if ( $c->{type} eq 'cookbook' ) {
      cmp_tree( $obj->path, $c->{tree} );
    }
    else {
      my $data = _thaw_file( $obj->path );

      my $id_field = $c->{type} eq 'bag' ? 'id' : 'name';
      my ($first, $last) = split "/", $c->{name};
      $last //= $first;
      is ( delete $data->{$id_field}, $last, "$c->{type} name set correctly in data file" );

      is_deeply( $data, $c->{empty}, "remaining fields correctly set for empty $c->{type}" )
        or diag explain($data);
    }
  }
}

sub cmp_tree {
  my ($path, $tree, $base) = @_;
  $base //= $path;
  my $children = [sort map { "$_" } dir($path)->children];
  my $expected = [sort map { "$_" } map { dir($path, $_) } keys %$tree];
  my $rel_path = dir($path)->relative(dir($base)->parent);
  is_deeply( $children, $expected, "child names correct for '$rel_path'" );
  for my $child ( keys %$tree ) {
    if (ref ($tree->{$child}) eq 'HASH') {
      my $obj = dir($path, $child);
      my $rel = $obj->relative($base);
      ok( -d $obj, "'$rel' is subdirectory"); 
      cmp_tree(dir($path, $child), $tree->{$child}, $base)
        if keys %{$tree->{$child}};
    }
    else {
      my $obj = file($path, $child);
      my $rel = $obj->relative($base);
      ok( -f file($path, $child), "'$rel' is a file");
    }
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
