package OpenAPI::PetStore::Client 0.01;
use 5.020;
use Moo 2;
use experimental 'signatures';

extends 'OpenAPI::PetStore::Client::Impl';

=head1 NAME

OpenAPI::PetStore::Client - Client for OpenAPI::PetStore

=head1 SYNOPSIS

  use 5.020;
  use OpenAPI::PetStore::Client;

  my $client = OpenAPI::PetStore::Client->new(
      server => 'https://petstore.swagger.io/v2',
  );
  my $res = $client->someMethod()->get;
  say $res;

=head1 METHODS

=head2 C<< findPets >>

  my $res = $client->findPets()->get;

Returns an array of L<< OpenAPI::PetStore::Pet >>.
Returns a L<< OpenAPI::PetStore::Error >>.

=cut

=head2 C<< addPet >>

  my $res = $client->addPet()->get;

Returns a L<< OpenAPI::PetStore::Pet >>.
Returns a L<< OpenAPI::PetStore::Error >>.

=cut

=head2 C<< deletePet >>

  my $res = $client->deletePet()->get;

Returns a L<< OpenAPI::PetStore::Error >>.

=cut

=head2 C<< find_pet_by_id >>

  my $res = $client->find_pet_by_id()->get;

Returns a L<< OpenAPI::PetStore::Pet >>.
Returns a L<< OpenAPI::PetStore::Error >>.

=cut

1;
