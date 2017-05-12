use 5.008000;

use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);
my $OPTIMIZE;

if ($Config{gccversion}) {
    $OPTIMIZE = '-O3 -Wall -W';
    # the dev directory is under VC now - look for a hidden file instead
    $OPTIMIZE .= ' -g -Wextra -Wdeclaration-after-statement' if (-f '.dev');
} elsif ($Config{osname} eq 'MSWin32') {
    $OPTIMIZE = '-O2 -W4';
} else {
    $OPTIMIZE = $Config{optimize};
}

WriteMakefile(
    NAME          => 'Scalar::Util::Numeric',
    VERSION_FROM  => 'lib/Scalar/Util/Numeric.pm',
    PREREQ_PM     => {},
    ABSTRACT_FROM => 'lib/Scalar/Util/Numeric.pm',
    AUTHOR        => 'chocolateboy <chocolate@cpan.org>, Michael G. Schwern <schwern@pobox.com>',
    LIBS          => [ '' ],
    DEFINE        => '',
    INC           => '-I.',
    OPTIMIZE      => $OPTIMIZE,
    ($EUMM_VERSION >= 6.48 ? (MIN_PERL_VERSION => '5.8.0') : ()),
    ($EUMM_VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    ($EUMM_VERSION >= 6.46 ?
        (META_MERGE => {
            resources => {
                repository => 'https://github.com/chocolateboy/Scalar-Util-Numeric',
                bugtracker => 'https://github.com/chocolateboy/Scalar-Util-Numeric/issues',
            },
        })
        : ()
    ),
);
