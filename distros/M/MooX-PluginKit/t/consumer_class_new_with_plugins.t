#!/usr/bin/env perl
use strictures 2;
use Test::More;

{
  package Consumer;
  use Moo;
  use MooX::PluginKit::Consumer;
  sub test { 'Consumer' }
}
{
  package Consumer::Foo;
  use Moo;
  sub test { 'Consumer::Foo' }
}
{
  package Consumer::Bar;
  use Moo;
  sub test { 'Consumer::Bar' }
}
{
  package Consumer::FooPlugin;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_applies_to 'Consumer::Foo';
  around test => sub{ my($o,$s)=@_; return('Consumer::FooPlugin', $s->$o()) };
}
{
  package Consumer::BarPlugin;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_applies_to 'Consumer::Bar';
  around test => sub{ my($o,$s)=@_; return('Consumer::BarPlugin', $s->$o()) };
}
{
  package Consumer::AllPlugin;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_includes 'Consumer::FooPlugin', 'Consumer::BarPlugin';
  around test => sub{ my($o,$s)=@_; return('Consumer::AllPlugin', $s->$o()) };
}

my $consumer = Consumer->new( plugins=>['::AllPlugin'] );
my $foo = $consumer->class_new_with_plugins('Consumer::Foo');
my $bar = $consumer->class_new_with_plugins('Consumer::Bar');

is_deeply(
  [$consumer->test()],
  ['Consumer::AllPlugin', 'Consumer'],
  'base consumer',
);

is_deeply(
  [$foo->test()],
  ['Consumer::FooPlugin', 'Consumer::AllPlugin', 'Consumer::Foo'],
  'sub object 1',
);

is_deeply(
  [$bar->test()],
  ['Consumer::BarPlugin', 'Consumer::AllPlugin', 'Consumer::Bar'],
  'sub object 2',
);

done_testing;
