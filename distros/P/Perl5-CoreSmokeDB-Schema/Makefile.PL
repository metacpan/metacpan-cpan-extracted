#! perl -w
use warnings;
use strict;

use ExtUtils::MakeMaker 6.55_02;

WriteMakefile(
    NAME          => 'Perl5::CoreSmokeDB::Schema',
    VERSION_FROM  => 'lib/Perl5/CoreSmokeDB/Schema.pm',
    ABSTRACT_FROM => 'lib/Perl5/CoreSmokeDB/Schema.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',
    LICENSE       => 'perl',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.55_02,
    },
    BUILD_REQUIRES => {
        'Test::Fatal'        => '0.01',
        'Test::Simple'       => '0.88',
        'Test::Warnings'     => '0.028',
        'Test::DBIC::SQLite' => '1.01',
        'JSON'               => '4.09',
    },
    PREREQ_PM => {
        'DBIx::Class'                 => '0.08271',
        'DBIx::Class::Schema::Loader' => '0.07049',
        'DBD::Pg'                     => '3.14.0',
        'DateTime::Format::Pg'        => '0.16013',
        'Exception::Class'            => '1.44',
    },

    MIN_PERL_VERSION => '5.010001',

    META_ADD => {
        'meta-spec' => {
            version    => 2,
        },
        'resources' => {
            homepage  => 'https://github.com/abeltje/Perl5-CoreSmokeDB-Schema.git',
            repository => {
                type   => 'git',
                url    => 'https://github.com:abeltje/Perl5-CoreSmokeDB-Schema.git',
                web    => 'https://github.com/abeltje/Perl5-CoreSmokeDB-Schema.git',
            },
#            x_IRC      => 'irc://irc.perl.org/#smoke',
        },
    },
);
