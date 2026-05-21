use v5.12.0;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'Software::License::MIT_0',
    AUTHOR             => q{ryoskzypu <ryoskzypu@proton.me>},
    VERSION_FROM       => 'lib/Software/License/MIT_0.pm',
    ABSTRACT_FROM      => 'lib/Software/License/MIT_0.pm',
    LICENSE            => 'open_source',
    MIN_PERL_VERSION   => 'v5.12.0',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test2::V1' => '0',
    },
    PREREQ_PM => {
        'Software::License' => '0.104007',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index    => {
            directory => [
                qw<
                    eg
                    examples
                    share
                    xt
                >
            ],
        },
        prereqs => {
            develop => {
                recommends => {
                    'App::CPANTS::Lint' => '0',
                    'Data::Printer'     => '0',
                    'Devel::Cover'      => '0',
                    'Devel::NYTProf'    => '0',
                    'Perl::Critic'      => '0',
                    'Perl::Tidy'        => '0',
                },
                requires => {
                    'Test::CPAN::Changes' => '0',
                    'Test::Kwalitee'      => '0',
                    'Test::Perl::Critic'  => '0',
                    'Test::Pod'           => '0',
                    'Test::Pod::Coverage' => '0',
                    'Test::Spelling'      => '0',
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ryoskzypu/Software-License-MIT_0.git',
                web  => 'https://github.com/ryoskzypu/Software-License-MIT_0',
            },
            bugtracker => {
                web => 'https://github.com/ryoskzypu/Software-License-MIT_0/issues',
            },
        },
        x_contributors => [
            q{ryoskzypu <ryoskzypu@proton.me>},
        ],
        x_spdx_expression => 'MIT-0',
    },
);

WriteMakefile(%WriteMakefileArgs);
