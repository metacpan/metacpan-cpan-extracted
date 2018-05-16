package Mojo::SAML;

use Mojo::Base -strict;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

use constant ();
use Exporter 'import';
use Mojo::Util;

our @doc_types = (qw/
  AssertionConsumerService
  AttributeConsumingService
  AuthnRequest
  ContactPerson
  EntityDescriptor
  KeyDescriptor
  KeyInfo
  NameIDPolicy
  Organization
  RequestedAttribute
  Signature
  SPSSODescriptor
/);

for my $type (@doc_types) {
  my $package = "Mojo::SAML::Document::$type";
  require(Mojo::Util::class_to_path($package));
  constant->import($type => $package);
}

our %EXPORT_TAGS = (
  'docs' => [ @doc_types ],
);
our @EXPORT_OK = @doc_types;

1;

=head1 NAME

Mojo::SAML - A SAML2 toolkit using the Mojo toolkit

=head1 DESCRIPTION

L<Mojo::SAML> is a project to build a SAML toolkit using the Mojo stack.
It is (for better or worse) completely reimplemented from the ground up.
It is considered extremely experimental and unstable (see L</CAVEATS>).

That said, it can do basic SAML interactions given the proper configuration.
For more on SAML, you might want to consult L<https://en.wikipedia.org/wiki/SAML_2.0> or L<https://wiki.oasis-open.org/security>.

=head1 CAVEATS

It currently has plenty of limitations and should be considered extremely experimental.
The API can and will change without warning until this warning is removed.

It also relies heavily on using the simpler SAML bindings and is only really workable for RSA keys.
Because of this, there are dependencies on L<Crypt::OpenSSL::RSA> and L<Crypt::OpenSSL::X509> which really should be optional, though they are required until other signing mechanisms are included.
Users are encouraged to add those modules to their own dependencies in case they become optional in the future.

Currently data extraction and documentation are very much separate sets of code.
It is not yet decided if this will continue or if some effort will be made to unify them.
This is a large part of the concern for api stability.

While most classes have API documentation, currently overall usage documentation is lacking.
For the time being, examples can be seen in the C<ex/> directory within the source repository and/or distribution, especially C<ex/webapp.pl>.
These examples will be modified as the API changes and eventually usage documentation should be written.

L<Mojo::XMLSig> has some tests, the rest has precious few tests.
There could always be more tests.

All of this should be improvable.
PRs and comments are most welcome.

=head1 EXPORTS

L<Mojo::SAML> exports nothing by default.
On request it can export any of the following symbols or tags.

=head2 XML Document Constructors

The following symbols are constant functions which return the full name of L<Mojo::SAML::Document> subclasses.
Their name is both the name of the subclass and the tag that they create.

=head3 AssertionConsumerService

Constant shortcut to L<Mojo::SAML::Document::AssertionConsumerService>.

=head3 AttributeConsumingService

Constant shortcut to L<Mojo::SAML::Document::AttributeConsumingService>.

=head3 AuthnRequest

Constant shortcut to L<Mojo::SAML::Document::AuthnRequest>.

=head3 ContactPerson

Constant shortcut to L<Mojo::SAML::Document::ContactPerson>.

=head3 EntityDescriptor

Constant shortcut to L<Mojo::SAML::Document::EntityDescriptor>.

=head3 KeyDescriptor

Constant shortcut to L<Mojo::SAML::Document::KeyDescriptor>.

=head3 KeyInfo

Constant shortcut to L<Mojo::SAML::Document::KeyInfo>.

=head3 NameIDPolicy

Constant shortcut to L<Mojo::SAML::Document::NameIDPolicy>.

=head3 Organization

Constant shortcut to L<Mojo::SAML::Document::Organization>.

=head3 RequestedAttribute

Constant shortcut to L<Mojo::SAML::Document::RequestedAttribute>.

=head3 Signature

Constant shortcut to L<Mojo::SAML::Document::Signature>.

=head3 SPSSODescriptor

Constant shortcut to L<Mojo::SAML::Document::SPSSODescriptor>.

=head2 Tags

=head3 :docs

Exports all of the above document type constants.

=head1 OTHER MODULES

While they aren't linked to from this module, some other modules that will likely be useful are:

=head2 Mojo::SAML::Names

L<Mojo::SAML::Names> is a (fairly incomplete) list of naming conventions and standard used in SAML.

=head2 Mojo::SAML::IdP

L<Mojo::SAML::IdP> is a tool for examining the entity metadata returned from an identity provider and extracting useful inforamation.

=head2 Mojo::XMLSig

L<Mojo::XMLSig> is a tool for signing and verifying XML documents.
Note that it is possible that this module could be spun out into its own distribution at some point.
If it does, this module will depend on it.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-SAML>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Joel Berger
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
