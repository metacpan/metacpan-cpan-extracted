package Mojo::SAML::Document::AuthnRequest;

use Mojo::Base 'Mojo::SAML::Document';

use Mojo::SAML::Names;

has template => sub { shift->build_template(<<'XML') };
%= tag 'samlp:AuthnRequest' => $self->tag_attrs => begin
  % if (defined(my $issuer = $self->issuer)) {
  <saml:Issuer><%= $issuer %></saml:Issuer>
  % }
  % if (my $policy = $self->nameid_policy) {
  <%= $policy %>
  % }
  <samlp:RequestedAuthnContext Comparison="exact">
    <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml:AuthnContextClassRef>
  </samlp:RequestedAuthnContext>
% end
XML

has id => sub { 'MOJOSAML_' . shift->get_guid };
has issue_instant => sub { shift->get_instant };
has [qw/
  assertion_consumer_service_index assertion_consumer_service_url
  protocol_binding provider_name destination
  is_passive force_authn issuer nameid_policy
/];

sub before_render {
  my $self = shift;
  my $idx = defined $self->assertion_consumer_service_index;
  my $url = defined $self->assertion_consumer_service_url;
  if ($idx && $url) {
    Carp::croak 'Cannot specify both index and url for AssertionConsumerService';
  } elsif (!($idx || $url)) {
    $self->assertion_consumer_service_index(0);
  }
}

sub tag_attrs {
  my $self = shift;
  my @attrs = (
    'xmlns:samlp' => 'urn:oasis:names:tc:SAML:2.0:protocol',
    'xmlns:saml'  => 'urn:oasis:names:tc:SAML:2.0:assertion',
    Version => '2.0',
    ID => $self->id,
    IssueInstant => $self->issue_instant,
  );

  if (defined(my $idx = $self->assertion_consumer_service_index)) {
    push @attrs, AssertionConsumerServiceIndex => $idx;
  }
  if (defined(my $url = $self->assertion_consumer_service_url)) {
    push @attrs, AssertionConsumerServiceURL => $url;
  }
  if (defined(my $binding = $self->protocol_binding)) {
    push @attrs, ProtocolBinding => Mojo::SAML::Names::binding($binding);
  }
  if (defined(my $dest = $self->destination)) {
    push @attrs, Destination => $dest;
  }

  if (defined(my $force = $self->force_authn)) {
    push @attrs, ForceAuthn => $force ? 'true' : 'false';
  }
  if (defined(my $passive = $self->is_passive)) {
    push @attrs, IsPassive => $passive ? 'true' : 'false';
  }

  return @attrs;
}

1;

=head1 NAME

Mojo::SAML::Document::AuthnRequest

=head1 DESCRIPTION

Represents an AuthnRequest SAML protocol tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::AuthnRequest> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 id

The ID of the request XML document, defaults to C<MOJOSAML_> concatenated with a GUID (see L<Mojo::SAML::Document/get_guid>).

=head2 issue_instant

The issue instant of the request, defaults to L<Mojo::SAML::Document/get_instant>.

=head2 assertion_consumer_service_index

The index of the response service, see L<Mojo::SAML::Document::AssertionConsumerService/index>.
Exactly one of this or L</assertion_consumer_service_url> is required, however if neither is given, this value will be set to C<0>.

=head2 assertion_consumer_service_url

The url of the response service.
Exactly one of this or L</assertion_consumer_service_index> is required.

=head2 destination

A url specifying where this request is being sent.
Optional but recommended.

=head2 force_authn

A boolean indicating if authentication should be forced.
May be omitted, but assumed false if not given.

=head2 protocol_binding

If L</assertion_consumer_service_url> is given then this specifies the binding type.
Can use a shortened form expanded via L<Mojo::SAML::Names/binding>.

=head2 provider_name

Optional.
The human readable name of the requester service for possible use in display by other agents.

=head2 is_passive

A boolean indicating if this authentication request should be passive (ie, not disrupt workflow if not authenticatble).
May be omitted, but assumed false if not given.

=head2 issuer

The entity id of the service that generated the request.
See L<Mojo::SAML::Document::EntityDescriptor/entity_id>.
Optional but recommended.

=head2 nameid_policy

Optional.
An instance of L<Mojo::SAML::Document::NameIDPolicy> specifying the nameid policy to be returned.
This is essentially asking for a username vs email address, etc; read more at that document type.
If omitted, any identifier for the subject may be returned.

=head2 template

A template specific to the document type.

=head1 METHODS

L<Mojo::SAML::Document::AuthnRequest> inherits all methods from L<Mojo::SAML::Document> and implements the following new ones.

=head2 tag_attrs

Generates a list of attributes for the tag.

