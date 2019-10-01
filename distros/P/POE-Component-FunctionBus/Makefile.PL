use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                => 'POE::Component::FunctionBus',
    VERSION_FROM        => 'lib/POE/Component/FunctionBus.pm',
    ABSTRACT            => 'lib/POE/Component/FunctionBus.pm',
    AUTHOR              => q{Paul G Webster <daemon@cpan.org>},
    LICENSE             => 'bsd',
    META_MERGE   => {
        dynamic_config  => 0,
        'meta-spec'     => {
            version         =>  2
        },
        no_index        => {
            directory       => [qw(examples t)],
        },
        prereqs         => {
            runtime         => {
                requires        => {
                    perl            =>  '5.0244'
                }
            }
        },
        resources => {
            bugtracker => {
                web => 'https://github.com/PaulGWebster/p5-POE-Component-FunctionBus/issues'
            },
            homepage   => 'https://github.com/PaulGWebster/p5-POE-Component-FunctionBus',
            license    => [
                'https://opensource.org/licenses/BSD-3-Clause'
            ],
            repository => {
                type => 'git',
                url  => 'https://github.com/PaulGWebster/p5-POE-Component-FunctionBus.git',
                web  => 'https://github.com/PaulGWebster/p5-POE-Component-FunctionBus',
            },
            x_IRC => 'irc://irc.freenode.net/#perl'
        },
    },
    PREREQ_PM => {
        'POE'   =>  '1.367'
    },
    EXE_FILES => [],
    test      => {TESTS => 't/*.t t/*/*.t'},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'POE-Component-FunctionBus-*' },
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
