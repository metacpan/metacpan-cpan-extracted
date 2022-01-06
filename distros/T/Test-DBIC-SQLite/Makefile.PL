#! perl -w
use strict;
use v5.10.1;

use ExtUtils::MakeMaker 6.55_03;

my $prereq_pm = {
    'Test::Simple'                     => '0.88',
    'DBIx::Class::Schema::Loader'      => '0.07047',
    'SQL::Translator'                  => '1.60',
    'Moo'                              => '2.00',
    'namespace::autoclean'             => '0.16',
    'DBD::SQLite'                      => '1.29',    # Test-dep of DBIx::Class
    'MooX::Params::CompiledValidators' => '0.04',
    'Type::Tiny'                       => '1.008',
};
my $build_requires = {
    'Test::Simple'   => 0.88,
    'Test::Warnings' => 0,
    'Test::Fatal'    => 0,
    'Test::Tester'   => 0,
    'YAML'           => 0,
};
my $configure_requires = {
    'ExtUtils::MakeMaker' => '6.55_03',
};

WriteMakefile(
    NAME          => 'Test::DBIC::SQLite',
    VERSION_FROM  => 'lib/Test/DBIC/SQLite.pm',
    ABSTRACT_FROM => 'lib/Test/DBIC/SQLite.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',
    LICENSE       => 'perl',

    CONFIGURE_REQUIRES => $configure_requires,
    BUILD_REQUIRES     => $build_requires,
    PREREQ_PM          => $prereq_pm,

    MIN_PERL_VERSION => '5.010001',
    META_ADD         => {
        'meta-spec' => { version => 2 },
        'resources' => {
            homepage   => 'https://github.com/abeltje/Test-DBIC-SQLite.git',
            repository => {
                type => 'git',
                url  => 'https://github.com/abeltje/Test-DBIC-SQLite.git',
            },
        },
        'x_IRC' => 'irc://irc.perl.org/#amsterdam.pm',
    },
);
