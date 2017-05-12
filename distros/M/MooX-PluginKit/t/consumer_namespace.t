#!/usr/bin/env perl
use strictures 2;
use Test::More;

{
  package ConsumerDefault;
  use Moo;
  use MooX::PluginKit::Consumer;
  sub test { 'ConsumerDefault' }
}
{
  package ConsumerCustom;
  use Moo;
  use MooX::PluginKit::Consumer;
  plugin_namespace 'ConsumerCustom::Plugs';
  sub test { 'ConsumerCustom' }
}
{
  package Root::Plugin;
  use Moo::Role;
  around test => sub{ my($o,$s)=@_; return('Root::Plugin', $s->$o()) };
}
{
  package ConsumerDefault::Plugin;
  use Moo::Role;
  around test => sub{ my($o,$s)=@_; return('ConsumerDefault::Plugin', $s->$o()) };
}
{
  package ConsumerCustom::Plugs::Plugin;
  use Moo::Role;
  around test => sub{ my($o,$s)=@_; return('ConsumerCustom::Plugs::Plugin', $s->$o()) };
}

my @tests = (
  [ConsumerDefault => [] => [qw( ConsumerDefault )]],
  [ConsumerCustom  => [] => [qw( ConsumerCustom )]],
  [ConsumerDefault => ['::Plugin'] => [qw( ConsumerDefault::Plugin ConsumerDefault )]],
  [ConsumerDefault => ['ConsumerDefault::Plugin'] => [qw( ConsumerDefault::Plugin ConsumerDefault )]],
  [ConsumerCustom  => ['::Plugin'] => [qw( ConsumerCustom::Plugs::Plugin ConsumerCustom )]],
  [ConsumerCustom  => ['ConsumerCustom::Plugs::Plugin'] => [qw( ConsumerCustom::Plugs::Plugin ConsumerCustom )]],
  [ConsumerDefault => ['::Plugin','Root::Plugin'] => [qw( Root::Plugin ConsumerDefault::Plugin ConsumerDefault )]],
  [ConsumerCustom  => ['::Plugin','Root::Plugin'] => [qw( Root::Plugin ConsumerCustom::Plugs::Plugin ConsumerCustom )]],
);

foreach my $test (@tests) {
  my ($class, $plugins, $expected) = @$test;

  my $actual = [ $class->new( plugins=>$plugins )->test() ];

  is_deeply(
    $actual, $expected,
    "$class with plugins " . join(', ', @$plugins),
  );
}

done_testing;
