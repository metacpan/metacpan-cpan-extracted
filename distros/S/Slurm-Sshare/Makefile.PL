use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

#Abort if not on an OS which supports Slurm
#Mainly because our regression tests assume an Unix-like environment,
#so this will eliminate automated warnings about test failures
#This list from http://search.cpan.org/~shay/perl-5.22.1/pod/perlport.pod#PLATFORMS and
#http://slurm.schedmd.com/platforms.html
my @SUPPORTED_OSES = qw(aix freebsd linux openbsd darwin solaris);
my @temp = grep { $_ eq $^O } @SUPPORTED_OSES;
die "OS unsupported\n" unless ( @temp );

WriteMakefile(
    NAME             => 'Slurm::Sshare',
    AUTHOR           => q{Tom Payerle <payerle@umd.edu>},
    VERSION_FROM     => 'lib/Slurm/Sshare.pm',
    ABSTRACT_FROM    => 'lib/Slurm/Sshare.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' =>  '0.98_05', #We need decent subtest support
	'Cwd' => 0,
	'File::Basename' => 0,
    },
    PREREQ_PM => {
        'Class::Accessor' => 0,
        'Carp' => 0,
	'base' => 0,
	'strict' => 0,
	'version' => 0,
	'warnings' => 0,
	#For sbalance
	'Getopt::Long' => 0,
	'Pod::Usage' => 0,
    },
    EXE_FILES => [ 'bin/sbalance' ],

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Slurm-Sshare-*' },
);
