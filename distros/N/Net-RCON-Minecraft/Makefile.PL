use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                => 'Net::RCON::Minecraft',
    AUTHOR              => [q{Ryan Thompson <rjt@cpan.org>}],
    VERSION_FROM        => 'lib/Net/RCON/Minecraft.pm',
    ABSTRACT_FROM       => 'lib/Net/RCON/Minecraft.pod',
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.010',
    CONFIGURE_REQUIRES  => { 'ExtUtils::MakeMaker' => 0, },
    EXE_FILES           => [ qw< bin/rcon-minecraft > ],

    TEST_REQUIRES       => { 'List::Util'                   => 1.33,
                             'Test::Exception'              => 0.43,
                             'Test::MockModule'             => 0.170,
                             'Test::More'                   => 1.30,
                             'Test::Output'                 => 1.03,
                             'Test::Warnings'               => 0.026,
                           },
    PREREQ_PM           => { 'IO::Select'                   => 1.17,
                             'IO::Socket::IP'               => 0.38,
                             'Mouse'                        => 0,
                             'Mouse::Util::TypeConstraints' => 0,
                             'Term::ANSIColor'              => 3.01,
                           },
    META_MERGE          => {
        resources => {
            'meta-spec' => { version => 2 },
            repository  => 'https://github.com/rjt-pl/Net-RCON-Minecraft.git',
            bugtracker  => 'https://github.com/rjt-pl/Net-RCON-Minecraft/issues',
        },
    },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',           },
    clean     => { FILES    => 'Net-RCON-Minecraft-*'                },
    test      => { TESTS    => 't/*.t t/bin/*.t'                     },
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
