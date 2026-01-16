package SBOM::CycloneDX::Hash;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::Enum;

use Types::Standard qw(Enum StrMatch);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

my %ALGO_LENGTH = (
    'MD5'          => 32,
    'SHA-1'        => 40,
    'SHA-256'      => 64,
    'SHA-384'      => 96,
    'SHA-512'      => 128,
    'SHA3-256'     => 64,
    'SHA3-384'     => 96,
    'SHA3-512'     => 128,
    'BLAKE2b-256'  => 64,
    'BLAKE2b-384'  => 96,
    'BLAKE2b-512'  => 128,
    'BLAKE3'       => 64,
    'Streebog-256' => 64,
    'Streebog-512' => 128,
);

has alg =>
    (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->HASH_ALGORITHMS()], coerce => sub { uc($_[0]) }, required => 1);

has content => (
    is       => 'rw',
    isa      => StrMatch [qr{^([a-fA-F0-9]{32}|[a-fA-F0-9]{40}|[a-fA-F0-9]{64}|[a-fA-F0-9]{96}|[a-fA-F0-9]{128})$}],
    required => 1,
    trigger  => 1
);

sub _trigger_content {
    Carp::croak 'Invalid hash length' if $ALGO_LENGTH{$_[0]->alg} != length($_[0]->content);
}

sub TO_JSON {

    my $self = shift;

    my $json = {alg => $self->alg, content => $self->content};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Hash - Hash

=head1 SYNOPSIS

    SBOM::CycloneDX::Hash->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Hash> provides the hash object.

=head2 METHODS

L<SBOM::CycloneDX::Hash> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Hash->new( %PARAMS )

Properties:

=over

=item C<alg>, The algorithm that generated the hash value.

=item C<content>, The value of the hash.

=back

=item $hash->_trigger_content

=item $hash->alg

=item $hash->content

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
