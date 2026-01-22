package SBOM::CycloneDX::CryptoProperties::CipherSuite;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has name                  => (is => 'rw', isa => Str);
has algorithms            => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });
has identifiers           => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });
has tls_groups            => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });
has tls_signature_schemes => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{name}                = $self->name                  if $self->name;
    $json->{algorithms}          = $self->algorithms            if @{$self->algorithms};
    $json->{identifiers}         = $self->identifiers           if @{$self->identifiers};
    $json->{tlsGroups}           = $self->tls_groups            if @{$self->tls_groups};
    $json->{tlsSignatureSchemes} = $self->tls_signature_schemes if @{$self->tls_signature_schemes};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::CipherSuite - Object representing
a cipher suite

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties::CipherSuite->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::CipherSuite> specifies the object
representing a cipher suite.

=head2 METHODS

L<SBOM::CycloneDX::CryptoProperties::CipherSuite> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::CryptoProperties::CipherSuite->new( %PARAMS )

Properties:

=over

=item * C<algorithms>, A list of algorithms related to the cipher suite.

=item * C<identifiers>, A list of common identifiers for the cipher suite.

=item * C<name>, A common name for the cipher suite.

=item * C<tls_groups>, A list of TLS named groups (formerly known as curves) for
this cipher suite. These groups define the parameters for key exchange algorithms
like ECDHE.

=item * C<tls_signature_schemes>, A list of signature schemes supported for cipher
suite. These schemes specify the algorithms used for digital signatures in TLS
handshakes and certificate verification.

=back

=item $cipher_suite->algorithms

=item $cipher_suite->identifiers

=item $cipher_suite->name

=item $cipher_suite->tls_groups

=item $cipher_suite->tls_signature_schemes

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
