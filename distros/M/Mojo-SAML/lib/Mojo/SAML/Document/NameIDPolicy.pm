package Mojo::SAML::Document::NameIDPolicy;

use Mojo::Base 'Mojo::SAML::Document';

use Mojo::SAML::Names;

has template => sub { shift->build_template(<<'XML') };
%= tag NameIDPolicy => $self->tag_attrs
XML

has [qw/allow_create format sp_name_qualifier/];

sub tag_attrs {
  my $self = shift;
  my @attrs = (
    xmlns => 'urn:oasis:names:tc:SAML:2.0:protocol',
  );
  if (defined(my $format = $self->format)) {
    push @attrs, Format => Mojo::SAML::Names::nameid_format($format);
  }
  if (defined(my $qual = $self->sp_name_qualifier)) {
    push @attrs, SPNameQualifier => $qual;
  }
  if (defined(my $create = $self->allow_create)) {
    push @attrs, AllowCreate => $create ? 'true' : 'false';
  }
  return @attrs;
}

1;

=head1 NAME

Mojo::SAML::Document::NameIDPolicy

=head1 DESCRIPTION

Represents an NameIDPolicy SAML protocol tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::NameIDPolicy> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 allow_create

Optional.
A boolean indicating whether the subject should be allowed to create an account if they don't already have one.
May be omitted, but assumed to be false if not given.

=head2 format

Optional.
The actual format, which may be shorted and then expanded via L<Mojo::SAML::Names/nameid_format>.
See that function for understood values, though more are possible.

=head2 sp_name_qualifier

Optional.
A namespace for the name to be returned (or created) other than the requester.

=head2 template

A template specific to the document type.

=head1 METHODS

L<Mojo::SAML::Document::NameIDPolicy> inherits all methods from L<Mojo::SAML::Document> and implements the following new ones.

=head2 tag_attrs

Generates a list of attributes for the tag.

