package Mojo::SAML::Document::AttributeConsumingService;

use Mojo::Base 'Mojo::SAML::Document';

has template => sub { shift->build_template(<<'XML') };
%= tag AttributeConsumingService => $self->tag_attrs => begin
  % my $lang = $self->lang;
  % for my $name (@{ $self->service_names }) {
  <%= tag ServiceName => 'xml:lang' => $lang => $name %>
  % }
  % for my $desc (@{ $self->service_descriptions }) {
  <%= tag ServiceDescriptor => 'xml:lang' => $lang => $desc %>
  % }
  % for my $attr (@{ $self->requested_attributes }) {
  <%= $attr %>
  % }
% end
XML

has index => sub { Carp::croak 'index is required' };
has lang => 'en';
has [qw/requested_attributes service_descriptions service_names/] => sub { [] };
has [qw/is_default/];

sub before_render {
  my $self = shift;
  Carp::croak 'index must be defined'
    unless defined($self->index);
  for my $method (qw/requested_attributes service_names/) {
    Carp::croak "$method cannot be empty" unless @{$self->$method};
  }
}

sub tag_attrs {
  my $self = shift;
  my @attrs = (
    xmlns => 'urn:oasis:names:tc:SAML:2.0:metadata',
    index => $self->index,
  );

  if (defined(my $default = $self->is_default)) {
    push @attrs, isDefault => $default ? 'true' : 'false';
  }

  return @attrs;
}

1;

=head1 NAME

Mojo::SAML::Document::AttributeConsumingService

=head1 DESCRIPTION

Represents an AttributeConsumingService SAML metadata tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::AttributeConsumingService> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 index

Required.
The numerical index of the service for reference at a later time.

=head2 is_default

A boolean indicating whether this service should be considered the default.
May be omitted, but assumed false if not given.
Note that if no services are marked as default, the first one will be used as de-facto default.

=head2 lang

The X<xml:lang> attribute value to apply to L</name> and L</service_name>
Optional, defaults to C<en>.

=head2 requested_attributes

An array reference of L<Mojo::SAML::Document::RequestedAttribute> instance.
Must not be empty at render time.

=head2 service_descriptions

An array reference of strings describing the service for human consumption.

=head2 service_names

An array reference of strings with than name of service for human consumption.
Must not be empty at render time.

=head2 template

A template specific to the document type.

=head1 METHODS

L<Mojo::SAML::Document::AttributeConsumingService> inherits all methods from L<Mojo::SAML::Document> and implements the following new ones.

=head2 before_render

Enforces that L</index> is defined and that L</requested_attributes> and L</service_names> are not empty at render time.

=head2 tag_attrs

Generates a list of attributes for the tag.


