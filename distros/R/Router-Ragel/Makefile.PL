use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $version = MM->parse_version('lib/Router/Ragel.pm');

WriteMakefile(
    NAME => 'Router::Ragel',
    AUTHOR => 'vividsnow',
    LICENSE => 'perl_5',
    VERSION_FROM => 'lib/Router/Ragel.pm',
    ABSTRACT_FROM => 'lib/Router/Ragel.pod',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'Inline' => 0,
        'Inline::C' => 0,
        'Inline::Filters::Ragel' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::LeakTrace' => 0,
        'Devel::Size' => 0,
        'URI::Escape::XS' => 0,
        'Encode' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'Router::Ragel' => {
                file => 'lib/Router/Ragel.pm',
                version => $version,
            },
        },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/vividsnow/Router-Ragel.git',
                web => 'https://github.com/vividsnow/Router-Ragel',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/Router-Ragel/issues',
            },
        },
        prereqs => {
            develop => {
                requires => {
                    'Benchmark' => 0,
                    'Router::XS' => 0,
                    'Router::R3' => 0,
                    'URI::Router' => 0,
                    'Plack::Request' => 0,
                    'Mojolicious' => 0,
                    'Test::Pod' => '1.41',
                    'Test::Pod::Coverage' => '1.08',
                    'Test::CheckManifest' => '0.9',
                    'Test::Spelling' => '0.12',
                    'Test::NoTabs' => 0,
                    'Test::EOL' => 0,
                    'Test::CPAN::Changes' => 0,
                    'Test::CPAN::Meta' => 0,
                    'Test::Kwalitee::Extra' => 0,
                    'JSON::PP' => 0,
                },
            },
        },
    },
    test => { TESTS => 't/*.t' },
);
