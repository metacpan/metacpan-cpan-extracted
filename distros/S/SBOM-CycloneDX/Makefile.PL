#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'SBOM-CycloneDX',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/SBOM/CycloneDX.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.016,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0'},
    PREREQ_PM          => {
        'Cpanel::JSON::XS'     => '0',
        'JSON::Validator'      => '0',
        'List::Util'           => '0',
        'Moo'                  => '0',
        'namespace::autoclean' => '0',
        'Type::Tiny'           => '0',
        'URI::PackageURL'      => '2.22',
        'UUID::Tiny'           => '0',
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-SBOM-CycloneDX',
                web  => 'https://github.com/giterlizzi/perl-SBOM-CycloneDX'
            },
        },
        x_purl => 'pkg:cpan/GDT/SBOM-CycloneDX'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'SBOM-CycloneDX-*'},
);
