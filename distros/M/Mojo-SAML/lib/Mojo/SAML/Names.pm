package Mojo::SAML::Names;

use Mojo::Base -strict;
use Carp ();
use Exporter 'import';

our @EXPORT_OK = (qw/attrname_format binding nameid_format/);

my %attrname_format_aliases = (
  unspecified => 'urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified',
  uri => 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',
  basic => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
);
my @attrname_formats = values %attrname_format_aliases;
my %valid_attrname_formats; @valid_attrname_formats{@attrname_formats} = (1) x @attrname_formats;

sub attrname_format {
  my ($in, $lax) = @_;
  return $attrname_format_aliases{$in} if exists $attrname_format_aliases{$in};
  return $in if $valid_attrname_formats{$in} || $lax;
  Carp::croak "$in is not a valid attrname format (or alias)";
}

my %binding_aliases = (
  SOAP => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
  'HTTP-Redirect' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
  'HTTP-POST' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
);
my @bindings = values %binding_aliases;
my %valid_bindings; @valid_bindings{@bindings} = (1) x @bindings;

sub binding {
  my ($in, $lax) = @_;
  return $binding_aliases{$in} if exists $binding_aliases{$in};
  return $in if $valid_bindings{$in} || $lax;
  Carp::croak "$in is not a valid binding (or alias)";
}

my %nameid_format_aliases = (
  unspecified => 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified',
  emailAddress => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
  X509SubjectName => 'urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName',
  WindowsDomainQualifiedName => 'urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName',
  kerberos => 'urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos',
  entity => 'urn:oasis:names:tc:SAML:2.0:nameid-format:entity',
  persistent => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
  transient => 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
);
my @nameid_formats = values %binding_aliases;
my %valid_nameid_formats; @valid_nameid_formats{@nameid_formats} = (1) x @nameid_formats;

sub nameid_format {
  my ($in, $lax) = @_;
  return $nameid_format_aliases{$in} if exists $nameid_format_aliases{$in};
  return $in if $valid_nameid_formats{$in} || $lax;
  Carp::croak "$in is not a valid nameid format";
}

1;

=head1 NAME

Mojo::SAML::Names - Functions that qualify shortened names

=head1 DESCRIPTION

There are several types of names that come in fully qualified form that are too verbose for day to day use.
This modules contains functions that provide qualified version of from short names.

=head1 FUNCTIONS

L<Mojo::SAML::Names> exports no functions by default but exports any of the following upon request.

=head2 attrname_format

  $name = attrname_format($name);
  $name = attrname_format($name, $lax);

Qualify an attrname format used by SAML.
Given a short or qualified name return the qualified name.
If the fully qualified name is not known the function throws an exception unless the lax flag is true.

  unspecified => 'urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified'
  uri => 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri'
  basic => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic'

=head2 binding

  $name = binding($name);
  $name = binding($name, $lax);

Qualify a binding used by SAML.
Given a short or qualified name return the qualified name.
If the fully qualified name is not known the function throws an exception unless the lax flag is true.

  SOAP => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP'
  'HTTP-Redirect' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect'
  'HTTP-POST' => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'

=head2 nameid_format

  $name = nameid_format($name);
  $name = nameid_format($name, $lax);

Qualify a nameid format used by SAML.
Given a short or qualified name return the qualified name.
If the fully qualified name is not known the function throws an exception unless the lax flag is true.

  unspecified => 'urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified'
  emailAddress => 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
  X509SubjectName => 'urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName'
  WindowsDomainQualifiedName => 'urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName'
  kerberos => 'urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos'
  entity => 'urn:oasis:names:tc:SAML:2.0:nameid-format:entity'
  persistent => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
  transient => 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'


