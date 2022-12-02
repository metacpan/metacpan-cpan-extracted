package Net::SAML2::Types;
use warnings;
use strict;

our $VERSION = '0.62'; # VERSION

# ABSTRACT: Custom Moose types for Net::SAML2

use Types::Serialiser;
use MooseX::Types -declare => [
    qw(
        SAMLRequestType
        signingAlgorithm
    )
];

use MooseX::Types::Moose qw(Str Int Num Bool ArrayRef HashRef Item);


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

version 0.62

=head2 SAMLRequestType

Enum which consists of two options: SAMLRequest and SAMLResponse

=head2 signingAlgorithm

Enum which consists of the following options: sha244, sha256, sha384, sha512
and sha1

=head1 AUTHOR

Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Chris Andrews and Others, see the git log.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
