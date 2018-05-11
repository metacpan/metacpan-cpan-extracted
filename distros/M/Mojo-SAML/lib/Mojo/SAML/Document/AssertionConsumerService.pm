package Mojo::SAML::Document::AssertionConsumerService;

use Mojo::Base 'Mojo::SAML::Document';

use Mojo::SAML::Names;

has template => sub { shift->build_template(<<'XML') };
%= tag AssertionConsumerService => $self->tag_attrs
XML

has binding  => sub { Carp::croak 'binding is required' };
has index    => sub { Carp::croak 'index is required' };
has location => sub { Carp::croak 'location is required' };
has [qw/is_default response_location/];

sub tag_attrs {
  my $self = shift;
  my $binding = $self->binding;
  my @attrs = (
    xmlns => 'urn:oasis:names:tc:SAML:2.0:metadata',
    index => $self->index,
    Location => $self->location,
    Binding => Mojo::SAML::Names::binding($binding),
  );

  if (defined(my $res = $self->response_location)) {
    push @attrs, ResponseLocation => $res;
  }

  if (defined(my $default = $self->is_default)) {
    push @attrs, isDefault => $default ? 'true' : 'false';
  }

  return @attrs;
}

1;

=head1 NAME

Mojo::SAML::Document::AssertionConsumerService

=head1 DESCRIPTION

Represents an AssertionConsumerService SAML metadata tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::AssertionConsumerService> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 binding

Required.
The name of the binding to be used.
Can use a shortened form expanded via L<Mojo::SAML::Names/binding>.

=head2 index

Required.
The numerical index of the endpoint for reference at a later time.

=head2 location

Required.
The location of the endpoint itself.

=head2 is_default

A boolean indicating whether this endpoint should be considered the default endpoint.
May be omitted, but assumed false if not given.

=head2 response_location

Optional.
Allows specifying a different location to send the response.

=head2 template

A template specific to the document type.

=head1 METHODS

L<Mojo::SAML::Document::AssertionConsumerService> inherits all methods from L<Mojo::SAML::Document> and implements the following new ones.

=head2 tag_attrs

Generates a list of attributes for the tag.

