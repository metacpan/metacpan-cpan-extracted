use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;

eval { pack 'q' } or die "Unsupported: 64-bit perl is required.\n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Protocol-Dqlite.git',
                web => 'https://github.com/FGasper/p5-Protocol-Dqlite',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Protocol-Dqlite/issues',
            },
        },
    },

    NAME         => 'Protocol::Dqlite',
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    VERSION_FROM => 'lib/Protocol/Dqlite.pm',         # finds \$VERSION
    ABSTRACT_FROM => 'lib/Protocol/Dqlite.pm',
    LICENSE      => 'perl',

    # pack q/Q:
    MIN_PERL_VERSION => 5.010000,
);
