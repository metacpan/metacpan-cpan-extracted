package Mojo::SAML::Document::KeyInfo;

use Mojo::Base 'Mojo::SAML::Document';

use Mojo::Template;
use Mojo::XMLSig;

my $isa = sub {
  my ($obj, $class) = @_;
  Scalar::Util::blessed($obj) && $obj->isa($class);
};

has template => sub { shift->build_template(<<'XML') };
<KeyInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
  % if (my $name = $self->name) {
  <KeyName><%= $name %></KeyName>
  % }
  <X509Data>
    <X509Certificate><%= $self->x509_string // '' %></X509Certificate>
  </X509Data>
</KeyInfo>
XML

has 'cert';
has 'name';

sub x509_string {
  my $self = shift;
  return undef unless my $cert = $self->cert;

  my $text = $cert->$isa('Crypt::OpenSSL::X509') ? $cert->as_string : undef;

  Carp::croak 'Unknown cert object type'
    unless defined $text;

  return Mojo::XMLSig::trim_cert($text);
}

1;

=head1 NAME

Mojo::SAML::Document::KeyInfo

=head1 DESCRIPTION

Represents an KeyInfo XML-Sig tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::KeyInfo> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 cert

Optional.
If given, it must be an instance of L<Crypt::OpenSSL::X509>.
If not given, the tag is still generated, however, the content of the X509Certificate tag will be empty.
It may later be filled in via some signing process.

=head2 name

Optional.
The certificate name, used by some applications to distinguish between possible certificates.

=head2 template

A template specific to the document type.

=head1 METHODS

L<Mojo::SAML::Document::KeyInfo> inherits all methods from L<Mojo::SAML::Document> and implements the following new ones.

=head2 x509_string

If the L</cert> is given, this method formats and returns it for inserting into the X509Certificate tag body.

