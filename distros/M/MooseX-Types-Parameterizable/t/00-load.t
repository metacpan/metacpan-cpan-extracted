use Test::Most tests=>3;

BEGIN {
  use_ok 'MooseX::Types::Parameterizable';
  use_ok 'MooseX::Meta::TypeConstraint::Parameterizable';
  use_ok 'MooseX::Meta::TypeCoercion::Parameterizable';
}
