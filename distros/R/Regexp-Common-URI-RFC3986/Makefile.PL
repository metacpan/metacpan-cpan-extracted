#!/usr/bin/perl

use 5.010;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my @tests = qw [t/*.t];

my %args = (
    NAME             => 'Regexp::Common::URI::RFC3986',
    VERSION_FROM     => 'lib/Regexp/Common/URI/RFC3986.pm',
    ABSTRACT_FROM    => 'lib/Regexp/Common/URI/RFC3986.pm',
    AUTHOR           => 'Jacques Deguest <jack@deguest.jp>',
    INSTALLDIRS      => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM        => {
        'strict'     => 0,
        'warnings'   => 0,
        'Exporter'   => 0,
    },
    TEST_REQUIRES =>
    {
        'lib'           => 0,
        'Test::More'    => 0,
    },
    LICENSE          => 'perl',
    MIN_PERL_VERSION => 5.010,
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Regexp-Common-URI-RFC3986-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec'  => { version => 2 },
        license      => ['perl_5'],
        prereqs      => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => 0,
                    'strict'              => 0,
                    'warnings'            => 0,
                },
            },
            runtime   => {
                requires => {
                    'strict'   => 0,
                    'warnings' => 0,
                    'Exporter' => 0,
                },
            },
            test      => {
                requires => {
                    'lib'        => 0,
                    'Test::More' => 0,
                },
            },
        },
        resources    => {
            bugtracker => {
                web => 'https://gitlab.com/jackdeguest/Regexp-Common-URI-RFC3986/-/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/jackdeguest/Regexp-Common-URI-RFC3986.git',
                web  => 'https://gitlab.com/jackdeguest/Regexp-Common-URI-RFC3986',
            },
        },
        keywords     => ['regular expression', 'URI', 'RFC3986', 'pattern'],
    }) : ()),
    test             => {
        TESTS => $^O eq 'MSWin32'
            ? "@{[map { glob } @tests]}"
            : "@tests"
    },
);

$args{BUILD_REQUIRES}     = $args{PREREQ_PM};
$args{CONFIGURE_REQUIRES} = $args{PREREQ_PM};
$args{TEST_REQUIRES}      = {
    %{ $args{PREREQ_PM} },
    'Test::More' => 0,
};

my %filter = (
    MIN_PERL_VERSION => '6.48',
    META_MERGE       => '6.46',
    AUTHOR           => '6.07',
    ABSTRACT_FROM    => '6.07',
    LICENSE          => '6.07',
);

delete $args{$_} for grep
{
    defined $filter{$_} && $ExtUtils::MakeMaker::VERSION lt $filter{$_}
} keys %args;

WriteMakefile %args;

__END__
