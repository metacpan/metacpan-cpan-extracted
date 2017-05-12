use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
 
my $eumm_ver = eval $ExtUtils::MakeMaker::VERSION;

my %META = (
    NAME             => 'Submodules',
    AUTHOR           => q{Francisco Zarabozo <zarabozo@cpan.org>},
    VERSION_FROM     => 'lib/Submodules.pm',
    ABSTRACT_FROM    => 'lib/Submodules.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'     => 0,
        'File::Spec'     => 0,
        'File::Find'     => 0,
        'File::Basename' => 0,
    },
    PREREQ_PM => {
        'File::Spec'     => 0,
        'File::Find'     => 0,
        'File::Basename' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Submodules-*' },
    META_MERGE => {
      no_index => {
        directory => [ 'fakelib', 'fakelib2' ],
      }
    }
);

delete $META{META_MERGE} if $eumm_ver < 6.46;
WriteMakefile(%META);
