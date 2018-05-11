package Mojo::SAML::Document::Organization;

use Mojo::Base 'Mojo::SAML::Document';

has [qw/display_names names urls/] => sub { [] };

has template => sub { shift->build_template(<<'XML') };
<Organization xmlns="urn:oasis:names:tc:SAML:2.0:metadata">
  % for my $name (@{ $self->names }) {
  <OrganizationName xml:lang="en"><%= $name %></OrganizationName>
  % }
  % for my $dn (@{ $self->display_names }) {
  <OrganizationDisplayName xml:lang="en"><%= $dn %></OrganizationDisplayName>
  % }
  % for my $url(@{ $self->urls }) {
  <OrganizationURL xml:lang="en"><%= $url %></OrganizationURL>
  % }
</Organization>
XML

sub before_render {
  my $self = shift;
  for my $method (qw/display_names names urls/) {
    Carp::croak "$method cannot be empty" unless @{$self->$method};
  }
}

1;

=head1 NAME

Mojo::SAML::Document::Organization

=head1 DESCRIPTION

Represents an Organization SAML metadata tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::Organization> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 display_names

An array reference containing the display names (human readable) of the organization.
Must not be empty at render time.

=head2 names

An array reference containing the machine readable name of the organization.
Must not be empty at render time.

=head2 template

A template specific to the document type.

=head2 urls

An array reference containing the urls of the organization.
Must not be empty at render time.

=head1 METHODS

L<Mojo::SAML::Document::Organization> inherits all methods from L<Mojo::SAML::Document> and implements the following new ones.

=head2 before_render

Enforces that L</display_names>, L</names>, and L</urls> are not empty at render time.

