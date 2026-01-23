use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'PDF::Reuse::Tutorial',
    'VERSION_FROM'	=> 'Tutorial.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    LICENSE => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cnighswonger/PDF-Reuse-Tutorial.git',
                web  => 'https://github.com/cnighswonger/PDF-Reuse-Tutorial',
            },
            bugtracker => {
                web => 'https://github.com/cnighswonger/PDF-Reuse-Tutorial/issues',
            },
        },
        provides => {
            'PDF::Reuse::Tutorial' => {
                file    => 'Tutorial.pm',
                version => '0.13',
            },
        },
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Tutorial.pm', # retrieve abstract from module
       AUTHOR     => [ 'Lars Lundberg larslund@cpan.org',
                       'Chris Nighswonger cnighs@cpan.org' ]) : ()),
);
