package Mojo::SAML::Document::ContactPerson;

use Mojo::Base 'Mojo::SAML::Document';

has template => sub { shift->build_template(<<'XML') };
% my @attrs = (xmlns => 'urn:oasis:names:tc:SAML:2.0:metadata', contactType => $self->type);
%= tag ContactPerson => @attrs => begin
  % if (my $name = $self->given_name) {
  <GivenName><%= $name %></GivenName>
  % }
  % if (my $surname = $self->surname) {
  <SurName><%= $surname %></SurName>
  % }
  % if (my $company = $self->company) {
  <Company><%= $company %></Company>
  % }
  % for my $email (@{ $self->emails }) {
  <EmailAddress>mailto:<%= $email %></EmailAddress>
  % }
  % for my $phone (@{ $self->telephone_numbers }) {
  <TelephoneNumber><%= $phone %></TelephoneNumber>
  % }
% end
XML

has type => sub { Carp::croak 'type is required' };
has [qw/given_name surname company/];
has [qw/emails telephone_numbers/] => sub { [] };

1;

=head1 NAME

Mojo::SAML::Document::ContactPerson

=head1 DESCRIPTION

Represents an ContactPerson SAML metadata tag

=head1 ATTRIBUTES

L<Mojo::SAML::Document::ContactPerson> inherits all attributes from L<Mojo::SAML::Document> and implements the following new ones.

=head2 company

Optional.
The company name of the contact.

=head2 emails

Optional.
An array reference containing contact email addresses.

=head2 given_name

Optional.
The given or first name of the contact.

=head2 surname

Optional.
The surname or last name of the contact.

=head2 telephone_numbers

Optional.
An array reference containing contact telephone numbers.

=head2 template

A template specific to the document type.

=head2 type

Required.
The type of contact this represents.
Should be one of C<technical>, C<support>, C<administrative>, C<billing>, and C<other>.

