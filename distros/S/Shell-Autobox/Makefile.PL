use 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);

WriteMakefile(
    NAME              => 'Shell::Autobox',
    VERSION_FROM      => 'lib/Shell/Autobox.pm', # finds $VERSION
    # compatibility in case module was previously installed to lib
    INSTALLDIRS     => ($] >= 5.011 ? 'site' : 'perl'),
    PREREQ_PM         => {
        autobox          => '2.85',
        'File::Temp'     => '0.16'
    },
    ABSTRACT_FROM        => 'lib/Shell/Autobox.pm',
    AUTHOR               => 'chocolateboy <chocolate@cpan.org>',
    ($EUMM_VERSION >= 6.48 ? (MIN_PERL_VERSION => '5.8.0') : ()),
    ($EUMM_VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    ($EUMM_VERSION >= 6.46 ?
        (META_MERGE => {
            resources => {
                repository => 'https://github.com/chocolateboy/Shell-Autobox',
                bugtracker => 'https://github.com/chocolateboy/Shell-Autobox/issues',
            },
        })
        : ()
    ),
);
