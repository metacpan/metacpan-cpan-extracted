#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use MooX::PluginKit::Core;

{
  package Plugin1;
  use Moo::Role;
  around test => sub{ my($o,$s)=@_; return( 'Plugin1', $s->$o() ) };
}
{
  package Plugin2;
  use Moo::Role;
  around test => sub{ my($o,$s)=@_; return( 'Plugin2', $s->$o() ) };
}
{
  package Plugin3;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_applies_to 'ConsumerBar';
  around test => sub{ my($o,$s)=@_; return( 'Plugin3', $s->$o() ) };
}
{
  package PluginFlat;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_includes 'Plugin1';
  around test => sub{ my($o,$s)=@_; return( 'PluginFlat', $s->$o() ) };
}
{
  package PluginDeep;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_includes 'PluginFlat';
  around test => sub{ my($o,$s)=@_; return( 'PluginDeep', $s->$o() ) };
}
{
  package PluginBranching;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_includes 'Plugin1', 'Plugin2';
  around test => sub{ my($o,$s)=@_; return( 'PluginBranching', $s->$o() ) };
}
{
  package PluginAppliesToTrunk;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_includes 'Plugin1', 'Plugin2';
  plugin_applies_to 'ConsumerFoo';
  around test => sub{ my($o,$s)=@_; return( 'PluginAppliesToTrunk', $s->$o() ) };
}
{
  package PluginAppliesToLeaf;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_includes 'Plugin1', 'Plugin3';
  around test => sub{ my($o,$s)=@_; return( 'PluginAppliesToLeaf', $s->$o() ) };
}

{ package ConsumerFoo; use Moo; sub test {} }
{ package ConsumerBar; use Moo; sub test {} }

my @plugins = qw( PluginFlat PluginDeep PluginBranching PluginAppliesToTrunk PluginAppliesToLeaf );

my @foo_tests = (
  [PluginFlat           => qw( Plugin1 PluginFlat)],
  [PluginDeep           => qw( Plugin1 PluginFlat PluginDeep )],
  [PluginBranching      => qw( Plugin2 Plugin1 PluginBranching )],
  [PluginAppliesToTrunk => qw( Plugin2 Plugin1 PluginAppliesToTrunk )],
  [PluginAppliesToLeaf  => qw( Plugin1 PluginAppliesToLeaf )],
);

my @bar_tests = (
  [PluginFlat           => qw( Plugin1 PluginFlat)],
  [PluginDeep           => qw( Plugin1 PluginFlat PluginDeep )],
  [PluginBranching      => qw( Plugin2 Plugin1 PluginBranching )],
  [PluginAppliesToTrunk => qw( )],
  [PluginAppliesToLeaf  => qw( Plugin3 Plugin1 PluginAppliesToLeaf )],
);

foreach my $class (qw( ConsumerFoo ConsumerBar )) {
  my @tests = ($class eq 'ConsumerFoo') ? @foo_tests : @bar_tests;

  foreach my $test (@tests) {
    my $plugin = shift( @$test );

    is(
      [ build_class_with_plugins( $class, $plugin )->new->test() ],
      $test,
      "$plugin applied to $class includes " . join(', ', @$test),
    );
  }
}

done_testing;
