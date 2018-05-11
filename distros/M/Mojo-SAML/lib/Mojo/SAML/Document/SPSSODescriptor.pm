package Mojo::SAML::Document::SPSSODescriptor;

use Mojo::Base 'Mojo::SAML::Document';

has template => sub { shift->build_template(<<'XML') };
<%
  my @attrs = (
    xmlns => 'urn:oasis:names:tc:SAML:2.0:metadata',
    protocolSupportEnumeration => 'urn:oasis:names:tc:SAML:2.0:protocol',
    AuthnRequestsSigned  => $self->authn_requests_signed  ? 'true' : 'false',
    WantAssertionsSigned => $self->want_assertions_signed ? 'true' : 'false',
  );
%>
%= tag SPSSODescriptor => @attrs => begin
  % for my $desc (@{ $self->key_descriptors }) {
  <%= $desc %>
  % }
  % for my $format (@{ $self->nameid_format }) {
  <NameIDFormat><%= nameid_format($format) %></NameIDFormat>
  % }
  % for my $service (@{ $self->assertion_consumer_services }) {
  <%= $service %>
  % }
  % for my $service (@{ $self->attribute_consuming_services }) {
  <%= $service %>
  % }
% end
XML

has [qw/authn_requests_signed want_assertions_signed/] => 0;
has [qw/key_descriptors assertion_consumer_services attribute_consuming_services nameid_format/] => sub { [] };

sub before_render {
  my $self = shift;
  for my $method (qw/assertion_consumer_services/) {
    Carp::croak "$method cannot be empty" unless @{$self->$method};
  }
}

1;

=head1 NAME

Mojo::SAML::Document::SPSSODescriptor

=head1 DESCRIPTION

Represents an SPSSODescriptor SAML metadata tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::SPSSODescriptor> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 authn_requests_signed

Optional.
A boolean specifying whether this service signs authn requests.
Defaults to false.

=head2 want_assertions_signed

Optional.
A boolean specifying whether this service requires assertions to be signed.
Defaults to false.

=head2 key_descriptors

An array reference of L<Mojo::SAML::Document::KeyDescriptor> objects containing descriptors of keys used by this service.

=head2 assertion_consumer_services

An array reference of L<Mojo::SAML::Document::AssertionConsumerService> elements.
Must not be empty at render time.

=head2 attribute_consuming_services

An array reference of L<Mojo::SAML::Document::AttributeConsumingService> elements.

=head2 nameid_format

An array reference of nameid formats that this service understands.

=head2 template

A template specific to the document type.

=head1 METHODS

L<Mojo::SAML::Document::SPSSODescriptor> inherits all methods from L<Mojo::SAML::Document> and implements the following new ones.

=head2 before_render

Enforces that L</assertion_consumer_services> is not empty at render time.

