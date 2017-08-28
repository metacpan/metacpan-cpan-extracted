package MooseX::DIC::Configuration::ServiceMetadata::Dependency;

use Exporter::Declare;

use Moose;

use MooseX::DIC::Types;

exports qw/ from_attribute from_yaml/;

has name => (is => 'ro', isa => 'Str', required => 1);
has scope => ( is => 'ro', isa => 'InjectionScope', default => 'object' );
has qualifiers => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] } );

# ( attribute: Moose::Meta::Attribute ) -> :Dependency
sub from_attribute {
  my $attribute = shift;
  
  my %params = ( name => $attribute->name );
  if( $attribute->does('MooseX::DIC::Injected') ) {
    $params{scope} = $attribute->scope if $attribute->scope;
    $params{qualifiers} = $attribute->qualifiers if $attribute->qualifiers;
  }

  return MooseX::DIC::Configuration::ServiceMetadata::Dependency->new(%params);
}

# ( dependency_name: Str, dependency_definition: HashRef) -> Dependency
sub from_yaml {
  my ($name,$definition) = @_;

  my %params = ( name => $name );
  $params{scope} = $definition->{scope} if exists($definition->{scope});
  $params{qualifiers} = $definition->{qualifiers} if exists($definition->{qualifiers});

  return MooseX::DIC::Configuration::ServiceMetadata::Dependency->new(%params);

}
__PACKAGE__->meta->make_immutable;
1;
