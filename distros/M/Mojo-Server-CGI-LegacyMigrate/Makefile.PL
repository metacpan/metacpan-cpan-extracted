use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Mojo::Server::CGI::LegacyMigrate',
    AUTHOR           => q{Evan Carroll <me@evancarroll.com>},
    VERSION_FROM     => 'lib/Mojo/Server/CGI/LegacyMigrate.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Server/CGI/LegacyMigrate.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    resources => {
      license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      bugtracker => {web => 'https://github.com/EvanCarroll/Mojo-Server-CGI-LegacyMigrate/issues'},
      repository => {
        type => 'git',
        url  => 'https://github.com/EvanCarroll/Mojo-Server-CGI-LegacyMigrate.git',
        web  => 'https://github.com/EvanCarroll/Mojo-Server-CGI-LegacyMigrate',
      },
    },
    PREREQ_PM => {
        'Mojolicious'  => '2.8'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojo-Server-CGI-LegacyMigrate-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
