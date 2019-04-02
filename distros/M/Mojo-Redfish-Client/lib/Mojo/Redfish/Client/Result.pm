package Mojo::Redfish::Client::Result;

use Mojo::Base -base;

use Carp ();
use Mojo::Collection;
use Mojo::JSON::Pointer;
use Scalar::Util ();

my $isa = sub { Scalar::Util::blessed($_[0]) && $_[0]->isa($_[1]) };

has client => sub { Carp::croak 'client is required' }, weak => 1;
has data   => sub { Carp::croak 'data is required' };

sub get {
  my ($self, $path) = @_;
  return $self unless defined $path;
  my $target = Mojo::JSON::Pointer->new($self->data)->get($path);
  return $self->_get($target);
}

sub value {
  my ($self, $path) = @_;
  return $self->data unless defined $path;

  my $target = Mojo::JSON::Pointer->new($self->data)->get($path);

  $target = Mojo::Collection->new(@$target)
    if ref $target eq 'ARRAY';

  return $target;
}

sub TO_JSON { shift->data }

sub _get {
  my ($self, $target) = @_;
  return $target
    if $target->$isa('Mojo::Redfish::Client::Result');

  $target = Mojo::Collection->new(@$target)
    if ref $target eq 'ARRAY';

  return $target->map(sub{ $self->_get($_) })
    if $target->$isa('Mojo::Collection');

  if (ref $target eq 'HASH') {
    if (keys %$target == 1 && exists $target->{'@odata.id'}) {
      $target = $target->{'@odata.id'};
    } else {
      return $self->_clone($target);
    }
  }

  return $self->client->get($target);
}

sub _clone {
  my ($self, $data) = @_;
  $self->new(
    client => $self->client,
    data   => ($data // $self->data),
  );
}

1;

=head1 NAME

Mojo::Redfish::Client::Result

=head1 DESCRIPTION

A class to get represent the result of a request from L<Mojo::Redfish::Client/get>.
It encapsulates the returned data and facilitates walking further out in the tree by following links.

=head1 ATTRIBUTES

L<Mojo::Redfish::Client::Result> inherits all of the attributes from L<Mojo::Base> and implements the following new ones.

=head2 client

An instance of L<Mojo::Redfish::Client>, usually the one that created this object.
Required and weakened.

=head2 data

The payload result from the Redfish request.

=head1 METHODS

L<Mojo::Redfish::Client::Result> inherits all of the methods from L<Mojo::Base> and implements the following new ones.

=head2 get

  $result = $result->get;
  my $deeper = $result->get('/deeper/key');

Get the value of the L</data> for the given JSON Pointer, making additional requests to follow links if needed.
Array values are upgraded to L<Mojo::Collection> objects and all (directly) contained values are fetched (if needed).
The result is always either a result object or a collection; use L</value> to get a simple value out of the data by pointer.

=head2 value

Similar to L</get> this method takes a pointer to dive into the L</data> however the result is never fetched from the Redfish server and the value is not upgraded to a results object.
Arrays are still upgraded to L<Mojo::Collection> objects.

=head2 TO_JSON

Alias for L</data> as a getter only.

=head1 SEE ALSO

=over

=item L<Mojo::Redfish::Client>

=back



