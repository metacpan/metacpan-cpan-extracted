package Mojo::SAML::Document::RequestedAttribute;

use Mojo::Base 'Mojo::SAML::Document';

use Mojo::SAML::Names;

has template => sub { shift->build_template(<<'XML') };
%= tag RequestedAttribute => $self->tag_attrs
XML

has name => sub { Carp::croak 'name is required' };
has [qw/is_required name_format friendly_name/];

sub tag_attrs {
  my $self = shift;
  my @attrs = (
    xmlns => 'urn:oasis:names:tc:SAML:2.0:metadata',
    Name  => $self->name,
  );
  if (defined(my $format = $self->name_format)) {
    push @attrs, NameFormat => Mojo::SAML::Names::attrname_format($format);
  }
  if (defined(my $name = $self->friendly_name)) {
    push @attrs, FriendlyName => $name;
  }
  if (defined(my $required = $self->is_required)) {
    push @attrs, isRequired => $required ? 'true' : 'false';
  }

  return @attrs;
}

1;

=head1 NAME

Mojo::SAML::Document::RequestedAttribute

=head1 DESCRIPTION

Represents an RequestedAttribute SAML metadata tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::RequestedAttribute> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 name

Required.
The machine-readable name of the attribute to be returned.

=head2 name_format

Optional.
The SAML-defined format of the attribute name or short alias as understood by L<Mojo::SAML::Names/attrname_format>.
Per the spec, if this is not given it is undestood to mean C<urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified>.

=head2 friendly_name

Optional.
The (possibly) human-readable name of the attribute to be returned.

=head2 is_required

A boolean indicating that this attribute is a required value.

=head2 template

A template specific to the document type.


