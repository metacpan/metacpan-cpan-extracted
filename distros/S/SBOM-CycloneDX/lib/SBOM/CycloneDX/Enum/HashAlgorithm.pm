package SBOM::CycloneDX::Enum::HashAlgorithm;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        MD5          => 'MD5',
        SHA_1        => 'SHA-1',
        SHA_256      => 'SHA-256',
        SHA_384      => 'SHA-384',
        SHA_512      => 'SHA-512',
        SHA3_256     => 'SHA3-256',
        SHA3_384     => 'SHA3-384',
        SHA3_512     => 'SHA3-512',
        BLAKE2B_256  => 'BLAKE2b-256',
        BLAKE2B_384  => 'BLAKE2b-384',
        BLAKE2B_512  => 'BLAKE2b-512',
        BLAKE3       => 'BLAKE3',
        STREEBOG_256 => 'Streebog-256',
        STREEBOG_512 => 'Streebog-512',
    );

    require constant;
    constant->import(\%ENUM);

    @EXPORT_OK   = sort keys %ENUM;
    %EXPORT_TAGS = (all => \@EXPORT_OK);

}

sub values { sort values %ENUM }

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Enum::HashAlgorithm - Hash Algorithm

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(HASH_ALGORITHM);

    say HASH_ALGORITHM->SHA_512;


    use SBOM::CycloneDX::Enum::HashAlgorithm;

    say SBOM::CycloneDX::Enum::HashAlgorithm->MD5;


    use SBOM::CycloneDX::Enum::HashAlgorithm qw(:all);

    say SHA1;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::HashAlgorithm> is ENUM package used by L<SBOM::CycloneDX>.

The algorithm that generated the hash value.


=head1 CONSTANTS

=over

=item * L<MD5>

=item * L<SHA_1>

=item * L<SHA_256>

=item * L<SHA_384>

=item * L<SHA_512>

=item * L<SHA3_256>

=item * L<SHA3_384>

=item * L<SHA3_512>

=item * L<BLAKE2B_256>

=item * L<BLAKE2B_384>

=item * L<BLAKE2B_512>

=item * L<BLAKE3>

=item * L<STREEBOG_256>

=item * L<STREEBOG_512>

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
