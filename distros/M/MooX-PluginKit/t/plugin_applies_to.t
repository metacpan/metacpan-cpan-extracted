#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use MooX::PluginKit::Core;

{
  package AppliesToDefault;
  use Moo::Role;
}
{
  package AppliesToAll;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_applies_to sub{ 1 };
}
{
  package AppliesToNone;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_applies_to sub{ 0 };
}
{
  package AppliesToPackage;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_applies_to 'FooPackage';
}
{
  package AppliesToDuck;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_applies_to ['foo', 'bar'];
}
{
  package AppliesToRegex;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  use Types::Standard -types;
  plugin_applies_to qr{FooRegex};
}
{
  package AppliesToCustom;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  use Types::Standard -types;
  plugin_applies_to sub{ $_[0] =~ m{FooCustom} };
}

my @classes = qw( FooPackage FooDuck FooRegex FooCustom );
{ package FooPackage }
{ package FooDuck; sub foo {} sub bar {} }
{ package FooRegex }
{ package FooCustom }

my @tests = (
  [ AppliesToDefault => 1, 1, 1, 1 ],
  [ AppliesToAll     => 1, 1, 1, 1 ],
  [ AppliesToNone    => 0, 0, 0, 0 ],
  [ AppliesToPackage => 1, 0, 0, 0 ],
  [ AppliesToDuck    => 0, 1, 0, 0 ],
  [ AppliesToRegex   => 0, 0, 1, 0 ],
  [ AppliesToCustom  => 0, 0, 0, 1 ],
);

foreach my $test (@tests) {
  my $plugin = shift( @$test );

  foreach my $class (@classes) {
    my $should_ok = shift( @$test );
    my $is_ok = does_plugin_apply( $plugin, $class );

    if ($should_ok) { ok($is_ok, "$plugin applies_to $class") }
    else { ok(!$is_ok, "$plugin does not applies_to $class") }
  }
}

done_testing;
