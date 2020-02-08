use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Portable::Dist',
    VERSION_FROM     => 'lib/Portable/Dist.pm',
    AUTHOR           => 'KMX',
    ABSTRACT         => 'Modify a Perl distribution to make it portable',
    MIN_PERL_VERSION => '5.008',
    LICENSE          => 'perl',
    PREREQ_PM => {
        'File::Spec'            => '3.47',
        'File::Slurper'         => '0.008',
        'Object::Tiny'          => '1.04',
        'Params::Util'          => '0.31',
        'File::Find::Rule'      => '0.30',
        'File::IgnoreReadonly'  => '0.01',
        'Test::More'            => '0.47',
        'File::Remove'          => '1.42',
        'File::Copy::Recursive' => '0.35',
        ($^O eq 'MSWin32' ? ('Win32::File::Object' => '0.01') : ('File::chmod' => '0.32')),
    },
    META_MERGE => {
      resources => {
        repository => 'https://github.com/StrawberryPerl/Portable-Dist',
        bugtracker => 'https://github.com/StrawberryPerl/Portable-Dist/issues',
      },
    },
    dist => {
      PREOP => 'perldoc -u lib/Portable/Dist.pm | pod2markdown > README.md',
      TAR => 'ptar',
      TARFLAGS => '-c -C -f'
    },
);
