use strict;
use warnings;

use Config;

my $ASAN = $ENV{'PROMISE_XS_ASAN'};

my $lddlflags = $Config{'lddlflags'};

my $cflags = q<>;

if ($ASAN) {
    $cflags .= " -fsanitize=address";
    $lddlflags .= " -fsanitize=address";
}

use ExtUtils::MakeMaker::CPANfile;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Promise::XS',
    VERSION_FROM      => 'lib/Promise/XS.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Promise/XS.pm', # retrieve abstract from module
       AUTHOR         => [
            'Felipe Gasper (FELIPE)',
            'Tom van der Woerdt <tomvanderwoerdt@sd.apple.com>',
        ],
      ) : ()
    ),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-Wall -I. $cflags",
    LICENSE           => "perl_5",

    LDDLFLAGS => $lddlflags,

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Promise-XS.git',
                web => 'https://github.com/FGasper/p5-Promise-XS',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Promise-XS/issues',
            },
        },
    },
);
