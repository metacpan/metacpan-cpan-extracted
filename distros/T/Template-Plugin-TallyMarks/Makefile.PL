use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Template::Plugin::TallyMarks',
    AUTHOR           => q{E. Choroba <choroba@cpan.org>},
    VERSION_FROM     => 'lib/Template/Plugin/TallyMarks.pm',
    ABSTRACT_FROM    => 'lib/Template/Plugin/TallyMarks.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE       => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 0,
        provides       => {
            'Template::Plugin::TallyMarks' => {
                file    => 'lib/Template/Plugin/TallyMarks.pm',
                version => 0.01,
            },
        },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/choroba/template-plugin-tallymarks.git',
                web => 'https://github.com/choroba/template-plugin-tallymarks',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    TEST_REQUIRES => {
        'Test::CheckManifest' => 0.9,
    },
    PREREQ_PM => {
        Template => 0,
        'Template::Plugin::Filter' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', TAR => 'ptar' },
    clean => { FILES => 'Template-Plugin-TallyMarks-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64') }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52') };

delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48') };

delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31') };

WriteMakefile(%WriteMakefileArgs);
