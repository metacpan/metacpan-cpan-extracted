# make a trait by using the main role
package MooseX::AttributeDefaults::Test::Trait;
use lib 't/lib';
use Moose::Role;

with qw(
  MooseX::AttributeDefaults::Test::Defaults
  MooseX::AttributeDefaults
);

package MooseX::AttributeDefaults::Test::TraitConsumer;
use Moose;

has attr => ( traits => [qw(MooseX::AttributeDefaults::Test::Trait)] );

package main;
use MooseX::AttributeDefaults::Test::TryClass;
use Test::More tests => 3;

run_tests qw(MooseX::AttributeDefaults::Test::TraitConsumer);
