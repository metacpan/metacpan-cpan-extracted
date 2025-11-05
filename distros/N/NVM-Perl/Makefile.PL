use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'NVM::Perl',
    DISTNAME        => 'NVM-Perl',
    VERSION_FROM    => 'lib/NVMPL/Core.pm',
    AUTHOR          => 'Jason Hall <jason.kei.hall@gmail.com>',
    ABSTRACT        => 'A Perl-based Node Version Manager',
    LICENSE         => 'perl',
    EXE_FILES       => ['bin/nvm-pl'],
    PREREQ_PM       => {
        'JSON::PP'              => 0,
        'HTTP::Tiny'            => 0,
        'File::HomeDir'         => 0,
        'Archive::Zip'          => 0,
        'Term::ANSIColor'       => 0,
        'Getopt::Long'          => 0,
        'File::Path'            => 0,
        'File::Spec'            => 0,
        'Exporter'              => 0,
    },

    BUILD_REQUIRES => {
        'Test::More'            => 0,
        'Test::MockModule'      => 0,
        'Test::Exception'       => 0,
        'File::Temp'            => 0,
        'FindBin'               => 0,
        'Capture::Tiny'         => 0, 
    },

    META_MERGE     => {
        'meta-spec' => { version => 2 },
        provides    => {
            'NVM::Perl' => {
                file    => 'lib/NVM/Perl.pm',
                version => '0.1.1',
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jkhall81/nvm-pl.git',
                web  => 'https://github.com/jkhall81/nvm-pl',
            },
            bugtracker => {
                web => 'https://github.com/jkhall81/nvm-pl/issues',
            },
        },
    },
    MIN_PERL_VERSION => '5.008',
);
