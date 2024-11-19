#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'STIX',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/STIX.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.016,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0'},
    PREREQ_PM          => {
        'Moo'                  => '0',
        'Type::Tiny'           => '0',
        'JSON::Validator'      => '0',
        'Cpanel::JSON::XS'     => '0',
        'List::Util'           => '0',
        'UUID::Tiny'           => '0',
        'namespace::autoclean' => '0',
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-STIX/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-STIX',
                web  => 'https://github.com/giterlizzi/perl-STIX'
            },
        },
        x_purl => 'pkg:cpan/GDT/STIX'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'STIX-*'},
);
