package MXJSTatt;

use Moose;
use MooseX::JSONSchema;

json_schema_title "An attribute";

has something => (
  traits => [qw( MooseX::JSONSchema::AttributeTrait )],
  json_schema_description => 'A something',
  json_schema_type => 'string',
  predicate => 'has_something',
  is => 'ro',
  isa => 'Str',
);

1;
