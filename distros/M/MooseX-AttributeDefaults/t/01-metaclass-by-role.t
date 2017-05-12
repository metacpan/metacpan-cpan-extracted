package MooseX::AttributeDefaults::Test::Metaclass;
use lib 't/lib';
use Moose;

extends 'Moose::Meta::Attribute';
with qw(
  MooseX::AttributeDefaults::Test::Defaults
  MooseX::AttributeDefaults
);

package MooseX::AttributeDefaults::Test::MetaclassConsumer;
use Moose;

has attr => (metaclass => 'MooseX::AttributeDefaults::Test::Metaclass');

package main;
use MooseX::AttributeDefaults::Test::TryClass;
use Test::More tests => 3;

run_tests qw(MooseX::AttributeDefaults::Test::MetaclassConsumer);
