use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'MooX::Role::Parameterized',
    DISTNAME           => "MooX-Role-Parameterized",
    AUTHOR             => 'Tiago Peczenyj <tiago.peczenyj+cpan@gmail.com>',
    LICENSE            => "mit",
    ABSTRACT_FROM      => 'lib/MooX/Role/Parameterized.pm',
    VERSION_FROM       => 'lib/MooX/Role/Parameterized.pm',
    MIN_PERL_VERSION   => 5.008,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0 },
    PREREQ_PM          => {
        'Carp'             => 0,
        'Module::Runtime'  => 0,
        'Moo'              => 2,
        'MooX::BuildClass' => 0.213360,
    },
    TEST_REQUIRES => {
        'Test::Exception' => 0.43,
        'Test::More'      => 0.94,
        'Test::Pod'       => 0,
    },
    (   eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? ( META_MERGE => {
                'meta-spec'    => { version => 2 },
                dynamic_config => 0,
                resources      => {
                    homepage =>
                      'https://github.com/peczenyj/MooX-Role-Parameterized',
                    repository => {
                        type => 'git',
                        url  =>
                          'https://github.com/peczenyj/MooX-Role-Parameterized.git',
                        web =>
                          'https://github.com/peczenyj/MooX-Role-Parameterized',
                    },
                    bugtracker => {
                        web =>
                          'https://github.com/peczenyj/MooX-Role-Parameterized/issues'
                    },
                },
                x_authority => 'cpan:PACMAN',
            }
          )
        : ()
    ),
);
