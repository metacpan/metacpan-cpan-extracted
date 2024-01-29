package Net::SAML2::RequestedAttribute;
use Moose;
use XML::Generator;
use URN::OASIS::SAML2 qw(URN_METADATA NS_METADATA);
our $VERSION = '0.76'; # VERSION

# ABSTRACT: RequestedAttribute class

has name => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has namespace => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { return [NS_METADATA() => URN_METADATA() ] },
);

has required => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);

has friendly_name => (
  is => 'ro',
  isa => 'Str',
  predicate => '_has_friendly',
);


has name_format => (
  is => 'ro',
  isa => 'Str',
  predicate => '_has_name_format',
);

has _xml_gen => (
  is => 'ro',
  isa => 'XML::Generator',
  default => sub { return XML::Generator->new() },
  init_arg => undef,
);

sub to_xml {
  my $self = shift;

  my %attrs = $self->_build_attributes;

  my $x = $self->_xml_gen();

  return $x->RequestedAttribute($self->namespace, \%attrs);

}

sub _build_attributes {
  my $self = shift;

  my %attrs = (
    $self->required ? (isRequired => 1) : (),
    Name => $self->name,
    $self->_has_friendly ? (FriendlyName => $self->friendly_name) : (),
  );
  return %attrs;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::RequestedAttribute - RequestedAttribute class

=head1 VERSION

version 0.76

=head1 SYNOPSIS

  use Net::SAML2::RequestedAttribute;

  my $attr = Net::SAML2::RequestedAttribute->new(
    # required
    name => 'Some:urn',

    # defaults to:
    namespace => 'md',

    # optional
    friendly_name => 'foo',
    required => 1,
  );

  my $fragment = $var->to_xml();

=head1 DESCRIPTION

=head1 METHODS

=head2 to_xml

Create an XML fragment

=head2 _build_attributes

A requested attribute can hold other attributes than the ones specified in the
XSD of L<https://docs.oasis-open.org/security/saml/v2.0/saml-schema-assertion-2.0.xsd>.

This method allows to override the attributes for the RequestedAttribute node
where you can add/remove/replace or change the order of the attributes. In
other OO frameworks this method would have been protected or common
(Object::Pad/Corrina).

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
