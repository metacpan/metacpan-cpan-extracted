use ExtUtils::MakeMaker;
use strict;
use warnings;

my %WriteMakefileArgs = (
    NAME                => 'Net::API::CPAN',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/Net/API/CPAN.pm',
    ABSTRACT_FROM       => 'lib/Net/API/CPAN.pm',
    PL_FILES            => {},
    EXE_FILES           => [qw( scripts/cpanapi )],
    PREREQ_PM           => {
        'constant'          => 0,
        'curry'             => 0,
        'open'              => 0,
        'parent'            => 0,
        'strict'            => 0,
        'utf8'              => 0,
        'vars'              => 0,
        'warnings'          => 0,
        'Changes'           => 'v0.3.1',
        'Clone'             => '0.46',
        # For cpanapi
        'Data::Pretty'      => 'v0.1.7',
        'DateTime'          => '1.59',
        'DateTime::Format::Strptime' => '1.79',
        'Email::Address::XS' => '1.05',
        'Encode'            => '3.19',
        # For cpanapi
        'Getopt::Class'     => 'v0.104.1',
        'HTTP::Promise'     => 'v0.5.3',
        'IO::Handle'        => '1.51',
        # For cpanapi
        'JSON'              => '4.10',
        'Module::Generic'   => 'v1.0.2',
        'Pod::Usage'        => '2.01',
        # For cpanapi
        'POSIX'             => '0',
        'Scalar::Util'      => 0,
        'Socket'            => '2.036',
        # For cpanapi
        'Term::ANSIColor::Simple' => '0.10',
        # For cpanapi
        'Term::Prompt'      => '1.04',
        # For cpanapi
        'Term::ReadKey'     => '2.38',
        'URI'               => '5.21',
        # Used for release information
        'URI::git'          => '0.02',
        'Wanted'            => 'v0.1.0',
    },
    TEST_REQUIRES =>
    {
        'lib'               => 0,
        'Test::More'        => '1.302162',
        'Test::Pod'         => '1.52',
        'Test::Time'        => '0.092',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.16.0',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp' },
    clean               => { FILES => 'Net-API-CPAN-* build/modules' },
    macro               => {
        build => './build/build_modules.pl',
    },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            # homepage    => undef,
            repository  => {
                url         => 'git@gitlab.com:jackdeguest/Net-API-CPAN.git',
                web         => 'https://gitlab.com/jackdeguest/Net-API-CPAN',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://gitlab.com/jackdeguest/Net-API-CPAN/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);

