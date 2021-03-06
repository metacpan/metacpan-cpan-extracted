package Paws::MarketplaceCatalog::Change;
  use Moose;
  has ChangeType => (is => 'ro', isa => 'Str', required => 1);
  has Details => (is => 'ro', isa => 'Str', required => 1);
  has Entity => (is => 'ro', isa => 'Paws::MarketplaceCatalog::Entity', required => 1);
1;

### main pod documentation begin ###

=head1 NAME

Paws::MarketplaceCatalog::Change

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::MarketplaceCatalog::Change object:

  $service_obj->Method(Att1 => { ChangeType => $value, ..., Entity => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::MarketplaceCatalog::Change object:

  $result = $service_obj->Method(...);
  $result->Att1->ChangeType

=head1 DESCRIPTION

An object that contains the C<ChangeType>, C<Details>, and C<Entity>.

=head1 ATTRIBUTES


=head2 B<REQUIRED> ChangeType => Str

  Change types are single string values that describe your intention for
the change. Each change type is unique for each C<EntityType> provided
in the change's scope.


=head2 B<REQUIRED> Details => Str

  This object contains details specific to the change type of the
requested change.


=head2 B<REQUIRED> Entity => L<Paws::MarketplaceCatalog::Entity>

  The entity to be changed.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::MarketplaceCatalog>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

