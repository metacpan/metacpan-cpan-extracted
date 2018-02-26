use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test::BDD::Cucumber::Definitions',
    AUTHOR           => q{Mikhail Ivanov <m.ivanych@gmail.com>},
    VERSION_FROM     => 'lib/Test/BDD/Cucumber/Definitions.pm',
    ABSTRACT_FROM    => 'lib/Test/BDD/Cucumber/Definitions.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Archive::Zip'                  => 0,
        'Const::Fast'                   => 0,
        'DDP'                           => 0,
        'Hash::MultiValue'              => 0,
        'HTTP::Response'                => 0,
        'HTTP::Tiny'                    => 0,
        'IO::String'                    => 0,
        'JSON::Path'                    => 0,
        'JSON::XS'                      => 0,
        'MooseX::Types'                 => 0,
        'MooseX::Types::Common'         => 0,
        'Params::ValidationCompiler'    => '0.22',
        'Test::BDD::Cucumber'           => 0,
        'Try::Tiny'                     => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
            bugtracker  => {
                web    => 'https://github.com/ivanych/Test-BDD-Cucumber-Definitions/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/ivanych/Test-BDD-Cucumber-Definitions.git',
                web  => 'https://github.com/ivanych/Test-BDD-Cucumber-Definitions',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-BDD-Cucumber-Definitions-*' },
);
