package Net::SAML2::Types;
use warnings;
use strict;

our $VERSION = '0.82'; # VERSION

# ABSTRACT: Custom Moose types for Net::SAML2

use Types::Serialiser;
use MooseX::Types -declare => [
    qw(
        XsdID
        SAMLRequestType
        signingAlgorithm
    )
];

use MooseX::Types::Moose qw(Str Int Num Bool ArrayRef HashRef Item);


subtype XsdID, as Str,
    where {
        return 0 unless $_ =~ /^[a-zA-Z_]/;
        return 0 if $_ =~ /[^a-zA-Z0-9_\.\-]/;
        return 1;
    },
    message { "'$_' is not a valid xsd:ID" };


subtype SAMLRequestType, as enum(
    [
        qw(SAMLRequest SAMLResponse)
    ]
    ),
    message { "'$_' is not a SAML Request type" };



subtype signingAlgorithm, as enum(
    [
        qw(sha244 sha256 sha384 sha512 sha1)
    ]
    ),
    message { "'$_' is not a supported signingAlgorithm" };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Types - Custom Moose types for Net::SAML2

=head1 VERSION

version 0.82

=head2 XsdID

The type xsd:ID is used for an attribute that uniquely identifies an element in an XML document. An xsd:ID value must be an NCName. This means that it must start with a letter or underscore, and can only contain letters, digits, underscores, hyphens, and periods.

=head2 SAMLRequestType

Enum which consists of two options: SAMLRequest and SAMLResponse

=head2 signingAlgorithm

Enum which consists of the following options: sha244, sha256, sha384, sha512
and sha1

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
