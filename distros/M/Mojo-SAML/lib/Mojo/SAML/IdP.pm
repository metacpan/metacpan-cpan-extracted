package Mojo::SAML::IdP;

use Mojo::Base -base;

use Mojo::XMLSig;

use Carp ();
use Mojo::DOM;
use Mojo::File;
use Mojo::UserAgent;
use Mojo::Util;
use Mojo::URL;
use Scalar::Util ();

my $isa = sub {
  my ($obj, $class) = @_;
  Scalar::Util::blessed($obj) && $obj->isa($class);
};
my %ns = (
  md => 'urn:oasis:names:tc:SAML:2.0:metadata',
  ds => 'http://www.w3.org/2000/09/xmldsig#',
);

has entity_id => sub {
  my $dom = shift->metadata;
  my $desc = $dom->find('md|EntityDescriptor[entityID]', %ns);
  Carp::croak 'Multiple EntityDescriptor elements found' if $desc->size > 1;
  Carp::croak 'No EntityDescriptor elements found' if $desc->size < 1;
  return $desc->[0]->{entityID};
};
has metadata => sub { Carp::croak 'metadata is required' };
has ua => sub { Mojo::UserAgent->new };

sub certificate_for {
  my ($self, $use) = @_;
  require Crypt::OpenSSL::X509;
  $use = Mojo::Util::xml_escape $use;
  my $s = qq!md|IDPSSODescriptor > md|KeyDescriptor[use="$use"] > ds|KeyInfo > ds|X509Data > ds|X509Certificate!;
  return undef unless my $elem = $self->entity->at($s, %ns);
  my $cert = Mojo::XMLSig::format_cert($elem->text);
  return Crypt::OpenSSL::X509->new_from_string($cert);
}

sub default_id_format {
  my $self = shift;
  my $formats = $self->_formats;
  return $formats->[0];
}

sub entity {
  my $self = shift;
  my $id = Mojo::Util::xml_escape $self->entity_id;
  return $self->metadata->at(qq<EntityDescriptor[entityID="$id"]>) // Carp::croak 'EntityDescriptor not found';
}

sub from_file {
  my ($self, $file) = @_;
  $file = Mojo::File->new("$file")
    unless $file->$isa('Mojo::File');
  return $self->from_xml(Mojo::Util::decode 'UTF-8', $file->slurp);
}

sub from_url {
  my ($self, $url) = @_;
  my $xml = $self->ua->get($url)->result->body;
  return $self->from_xml($xml);
}

sub from_xml {
  my ($self, $dom) = @_;
  $dom = Mojo::DOM->new->xml(1)->parse("$dom")
    unless $dom->$isa('Mojo::DOM');
  return $self->metadata($dom);
}

sub location_for {
  my ($self, $service, $binding) = @_;
  $binding = Mojo::SAML::Names::binding($binding);
  my $elem = $self->entity->at(qq!md|IDPSSODescriptor > md|${service}[Binding="$binding"][Location]!, %ns) || {};
  return Mojo::URL->new($elem->{Location});
}

sub name_id_format {
  my ($self, $format) = @_;
  my $formats = $self->_formats;
  return $formats->to_array unless defined $format;
  return $formats->first(sub{ $_ eq $format }) if $format =~ /:/;
  $format = qr/urn:oasis:names:tc:SAML:(?:2.0|1.1):nameid-format:\Q$format/;
  return $formats->first($format);
}

sub public_key_for {
  my ($self, $use) = @_;
  require Crypt::OpenSSL::RSA;
  my $cert = $self->certificate_for($use);
  return Crypt::OpenSSL::RSA->new_public_key($cert->pubkey);
}

sub verify_signature {
  my ($self, $key) = @_;
  my $dom = $self->metadata;
  return undef unless Mojo::XMLSig::has_signature($dom);
  return Mojo::XMLSig::verify($dom, $key);
}

sub _formats {
  my $self = shift;
  return $self->entity
    ->find(q!md|IDPSSODescriptor md|NameIDFormat!, %ns)
    ->map(sub{ Mojo::Util::trim $_->text });
}

1;

=head1 NAME

Mojo::SAML::IdP - A convenience module to extract information from an IdP entity descriptor document

=head1 SYNOPSIS

=head1 DESCRIPTION

L<Mojo::SAML::IdP> is a convenience class for extracting information from IdP entity descriptor metadata.
This module is especially fragile and will change as its usefulness is assessed and improved.

=head1 ATTRIBUTES

L<Mojo::SAML::IdP> inherits all of the attributes from L<Mojo::Base> and implements the following new ones.

=head2 entity_id

The entity id (C<entityID>) of the entity to be inspected.
If the L</metdata> contains only one entity descriptor, it will default to that id.
Otherwise, it must be specified manually otherwise it will throw an exception.

=head2 metadata

The metadata of the entity, as a L<Mojo::DOM> object.
Note that there are several methods which can be used to populate this values.
Otherwise accessing it without it being set will throw an exception.

=head2 ua

An instance of L<Mojo::UserAgent> used to fetch remote metadata.

=head1 METHODS

L<Mojo::SAML::IdP> inherits all of the methods from L<Mojo::Base> and implements the following new ones.

=head2 certificate_for

  my $cert = $idp->certificate_for($use);

Returns a C<Crypt::OpenSSL::X509> instance for the L</entity> and a given use.

=head2 default_id_format

  my $format = $idp->default_id_format;

Returns the first nameid format.

=head2 entity

  my $entity = $idp->entity;

Get the L<Mojo::DOM> instance for the entity identified by the L</entity_id>.
This is used by many other methods for picking the entity information.

=head2 from_file

  my $idp = Mojo::SAML::IdP->new->from_file($path);

Load L</metadata> from a given file.
Return the instance, designed to chain with C<new>.

=head2 from_url

  my $idp = Mojo::SAML::IdP->new->from_url($url);

Load L</metadata> from a given url using the L</ua>.
Return the instance, designed to chain with C<new>.

=head2 from_xml

  my $idp = Mojo::SAML::IdP->new->from_xml($url);

Load L</metadata> from a given string.
Return the instance, designed to chain with C<new>.

=head2 location_for

  my $url = $idp->location_for($service, $binding);

Extract a L<Mojo::URL> for the L</entity>'s given service and binding.
The binding may be shortend in a manner that can be fully qualified via L<Mojo::SAML::Names/binding>.

=head2 name_id_format

  $format = $idp->name_id_format($format);

Return the nameid format for the L</entity> if the nameid format given is accepted.
The format may be shortend in a manner that can be fully qualified via L<Mojo::SAML::Names/nameid_format>.

=head2 public_key_for

  my $pub = $idp->public_key_for($use);

A wrapper for L</certificate_for> which returns a L<Crypt::OpenSSL::RSA> public key instance for the certificate.

=head2 verify_signature

  my $verified = $idp->verify_signature;
  my $verified = $idp->verify_signature($pub);

Verify the metadata file's signature, either against itself or against a passed in public key.
Returns undef if no signature is found or a boolean signifying verification.

