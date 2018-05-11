package Mojo::SAML::Document::KeyDescriptor;

use Mojo::Base 'Mojo::SAML::Document';

has template => sub { shift->build_template(<<'XML') };
% my @attrs = (xmlns => 'urn:oasis:names:tc:SAML:2.0:metadata');
% if (my $use = $self->use) { push @attrs, (use => $use) }
%= tag KeyDescriptor => @attrs => begin
  <%= $self->key_info %>
% end
XML

has key_info => sub { Carp::croak 'key_info is required' };
has 'use';

1;

=head1 NAME

Mojo::SAML::Document::KeyDescriptor

=head1 DESCRIPTION

Represents an KeyDescriptor SAML metadata tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::KeyDescriptor> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 key_info

Required.
An instance of L<Mojo::SAML::Document::KeyInfo> containing information about the relevant key.

=head2 template

A template specific to the document type.

=head2 use

A string indicating if this key is used for C<signing> or C<encryption>.
This field should be optional, and when omitted it should indicate that the key is used for both uses.
In practice, the author has seen services that require that if a key is used for both purposes, it should be specified twice, once for each use.

