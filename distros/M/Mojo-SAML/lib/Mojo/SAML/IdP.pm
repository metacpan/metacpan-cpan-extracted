package Mojo::SAML::IdP;

use Mojo::Base 'Mojo::SAML::Entity';

has 'role_type' => 'IdP';

1;

=head1 NAME

Mojo::SAML::IdP - Subclass of Mojo::SAML::Entity focused on the IdP role

=head1 ATTRIBUTES

L<Mojo::SAML::IdP> inherits all of the attributes from L<Mojo::SAML::Entity> and implements the following new ones.

=head2 role_type

Same as L<Mojo::SAML::Entity/role_type> but defaults to C<IdP>.

