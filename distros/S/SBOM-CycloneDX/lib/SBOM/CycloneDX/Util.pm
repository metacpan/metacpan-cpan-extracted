package SBOM::CycloneDX::Util;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use URI::PackageURL;
use UUID::Tiny ':std';

use Exporter qw(import);

our @EXPORT = qw(
    urn_uuid urn_cdx
    cpan_meta_to_spdx_license
    cyclonedx_tool cyclonedx_component
    file_read file_write
);

require SBOM::CycloneDX::Component;
require SBOM::CycloneDX::ExternalReference;
require SBOM::CycloneDX::License;
require SBOM::CycloneDX::Tool;


# CPAN::Meta::Spec | SPDX                      | Description
# -----------------|---------------------------|--------------------------------
my %CPAN_META_SPEC_LICENSE_MAPPING = (
    agpl_3      => 'AGPL-3.0',                # GNU Affero General Public License, Version 3
    apache_1_1  => 'Apache-1.1',              # Apache Software License, Version 1.1
    apache_2_0  => 'Apache-2.0',              # Apache License, Version 2.0
    artistic_1  => 'Artistic-1.0',            # Artistic License, (Version 1)
    artistic_2  => 'Artistic-2.0',            # Artistic License, Version 2.0
    bsd         => 'BSD-3-Clause',            # BSD License (three-clause)
    freebsd     => 'BSD-2-Clause-FreeBSD',    # FreeBSD License (two-clause)
    gfdl_1_2    => 'GFDL-1.2',                # GNU Free Documentation License, Version 1.2
    gfdl_1_3    => 'GFDL-1.3',                # GNU Free Documentation License, Version 1.3
    gpl_1       => 'GPL-1.0',                 # GNU General Public License, Version 1
    gpl_2       => 'GPL-2.0',                 # GNU General Public License, Version 2
    gpl_3       => 'GPL-3.0',                 # GNU General Public License, Version 3
    lgpl_2_1    => 'LGPL-2.1',                # GNU Lesser General Public License, Version 2.1
    lgpl_3_0    => 'LGPL-3.0',                # GNU Lesser General Public License, Version 3.0
    mit         => 'MIT',                     # MIT (aka X11) License
    mozilla_1_0 => 'MPL-1.0',                 # Mozilla Public License, Version 1.0
    mozilla_1_1 => 'MPL-1.1',                 # Mozilla Public License, Version 1.1
    openssl     => 'OpenSSL',                 # OpenSSL License
    perl_5      => 'Artistic-1.0-Perl',       # The Perl 5 License (Artistic 1 & GPL 1 or later)
    qpl_1_0     => 'QPL-1.0',                 # Q Public License, Version 1.0
    ssleay      => 'SSLeay-standalone',       # Original SSLeay License
    sun         => 'SISSL',                   # Sun Internet Standards Source License (SISSL)
    zlib        => 'Zlib',                    # zlib License
);

# From CPAN::Meta::Spec
#
#   The following license strings are also valid and indicate other licensing not described above:
#
#   string          description
#   -------------   -----------------------------------------------
#   open_source     Other Open Source Initiative (OSI) approved license
#   restricted      Requires special permission from copyright holder
#   unrestricted    Not an OSI approved license, but not restricted
#   unknown         License not provided in metadata


sub urn_uuid { sprintf 'urn:uuid:%s', create_uuid_as_string(UUID_V4) }
sub urn_cdx  { sprintf 'urn:cdx:%s',  create_uuid_as_string(UUID_V4) }

sub cyclonedx_component {

    my $purl = URI::PackageURL->new(
        type      => 'cpan',
        namespace => 'GDT',
        name      => 'SBOM-CycloneDX',
        version   => $SBOM::CycloneDX::VERSION
    );

    my $component = SBOM::CycloneDX::Component->new(
        type                => 'library',
        group               => 'CPAN',
        name                => 'SBOM-CycloneDX',
        version             => sprintf('%s', $SBOM::CycloneDX::VERSION),
        description         => 'Perl distribution for CycloneDX',
        licenses            => [SBOM::CycloneDX::License->new(id => cpan_meta_to_spdx_license('artistic_2'))],
        purl                => $purl,
        bom_ref             => $purl->to_string,
        external_references => _cyclonedx_external_references()
    );

    return $component;

}

sub cyclonedx_tool {

    SBOM::CycloneDX::Tool->new(
        vendor              => 'CPAN',
        name                => 'SBOM-CycloneDX',
        version             => sprintf('%s', $SBOM::CycloneDX::VERSION),
        external_references => _cyclonedx_external_references()
    );

}

sub _cyclonedx_external_references {

    my @references = (
        {type => 'website',       url => 'https://metacpan.org/pod/SBOM::CycloneDX'},
        {type => 'documentation', url => 'https://metacpan.org/dist/SBOM-CycloneDX'},
        {type => 'vcs',           url => 'https://github.com/giterlizzi/perl-SBOM-CycloneDX'},
        {type => 'issue-tracker', url => 'https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues'},
        {type => 'license',       url => 'https://github.com/giterlizzi/perl-SBOM-CycloneDX/blob/main/LICENSE'},
        {type => 'release-notes', url => 'https://github.com/giterlizzi/perl-SBOM-CycloneDX/blob/main/Changes'},
        {type => 'distribution',  url => 'https://metacpan.org/dist/SBOM-CycloneDX'}
    );

    return [map { SBOM::CycloneDX::ExternalReference->new(%{$_}) } @references];

}

sub cpan_meta_to_spdx_license {
    return $CPAN_META_SPEC_LICENSE_MAPPING{$_[0]} || undef;
}

sub file_read {

    my $file = shift;

    if (ref($file) eq 'GLOB') {
        return do { local $/; <$file> };
    }

    return do {
        open(my $fh, '<', $file) or Carp::croak qq{Failed to read file: $!};
        local $/ = undef;
        <$fh>;
    };

}

sub file_write {

    my ($file, $content) = @_;

    my $fh = undef;

    if (ref($file) eq 'GLOB') {
        $fh = $file;
    }
    else {
        open($fh, '>', $file) or Carp::croak "Can't open file: $!";
    }

    $fh->autoflush(1);

    print $fh $content;
    close($fh);

}


1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Util - Utility for CycloneDX

=head1 SYNOPSIS

    use SBOM::CycloneDX::Util qw(cpan_meta_to_spdx_license);

    say cpan_meta_to_spdx_license('artistic_2'); # Artistic-2.0


=head1 DESCRIPTION

L<SBOM::CycloneDX::Utility> provides a set of utility for L<SBOM::CycloneDX>.

=head2 FUNCTIONS

=over

=item urn_uuid

Return a random URN UUID

=item urn_cdx

Return a random CDX UUID

=item cyclonedx_component

Return the representation of L<SBOM::CycloneDX> component using
L<SBOM::CycloneDX::Component> object.

=item cyclonedx_tool

Return the representation of L<SBOM::CycloneDX> tool using
L<SBOM::CycloneDX::Tool> object.

=item cpan_meta_to_spdx_license

Convert the L<CPAN::Meta> license to SPDX license identifier.

=item file_read

Read a file.

=item file_write

Write a content to file.

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

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
