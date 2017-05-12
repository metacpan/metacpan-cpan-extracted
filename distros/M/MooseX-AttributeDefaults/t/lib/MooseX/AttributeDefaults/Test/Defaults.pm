# Used by the tests to mixin a default_options role for less typing
package MooseX::AttributeDefaults::Test::Defaults;
use Moose::Role;

sub default_options {
  my ($class, $name) = @_;

  return (
    is      => 'ro',
    isa     => 'Str',
    default => "default value for $name",
  );
}

no Moose::Role;
1;
