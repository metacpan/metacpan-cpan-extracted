package Mojo::SAML::Document::EntityDescriptor;

use Mojo::Base 'Mojo::SAML::Document';

use Mojo::XMLSig;
use Mojo::SAML::Document::Signature;

has template => sub { shift->build_template(<<'XML') };
%= tag EntityDescriptor => $self->tag_attrs, begin
  % for my $desc (@{ $self->descriptors }) {
  <%= $desc %>
  % }
% end
XML

has descriptors => sub { [] };
has entity_id => sub { Carp::croak 'entity_id is required' };
has [qw/id valid_until cache_duration/];

sub tag_attrs {
  my $self = shift;
  my @attrs = (
    xmlns => 'urn:oasis:names:tc:SAML:2.0:metadata',
    entityID => $self->entity_id,
  );
  if (defined(my $id = $self->id)) {
    push @attrs, ID => $id;
  }
  if (defined(my $valid = $self->valid_until)) {
    push @attrs, validUntil => $valid;
  }
  if (defined(my $cache = $self->cache_duration)) {
    push @attrs, cacheDuration => $cache;
  }

  return @attrs;
}

sub before_render {
  my $self = shift;
  Carp::croak 'entity_id must be defined'
    unless defined($self->entity_id);
  for my $method (qw/descriptors/) {
    Carp::croak "$method cannot be empty" unless @{$self->$method};
  }
}

1;

=head1 NAME

Mojo::SAML::Document::EntityDescriptor

=head1 DESCRIPTION

Represents an EntityDescriptor SAML metadata tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::EntityDescriptor> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 cache_duration

Optional.
The maximum length of time to cache the data.

=head2 descriptors

An array reference containing documents of service descriptors.
This may include L<Mojo::SAML::Document::SPSSODescriptor>.
Must not be empty at render time.

=head2 entity_id

Required.
This is the identifier for the entity.
It is often the same as the assertion consumer service location (url, see L<Mojo::SAML::Document::AssertionConsumerService/location>).

=head2 id

Optional.
The ID of the XML element.

=head2 template

A template specific to the document type.

=head2 valid_until

Optional.
Speficies the time at which the document should no longer be considered valid.

=head1 METHODS

L<Mojo::SAML::Document::EntityDescriptor> inherits all methods from L<Mojo::SAML::Document> and implements the following new ones.

=head2 before_render

Enforces that L</descriptors> is not empty at render time.

=head2 tag_attrs

Generates a list of attributes for the tag.

