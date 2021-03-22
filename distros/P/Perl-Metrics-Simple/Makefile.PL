# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
###############################################################################
use strict;
use warnings;
use 5.006001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Perl::Metrics::Simple',
    ABSTRACT_FROM => 'lib/Perl/Metrics/Simple.pm',
    AUTHOR        => 'J Matisse Enzer <matisse@cpan.org>',
    VERSION_FROM  => 'lib/Perl/Metrics/Simple.pm',           # finds $VERSION
    EXE_FILES     => ['bin/countperl'],
    PL_FILES      => {},
    PREREQ_PM     => {
        'Carp'                      => 0,
        'Data::Dumper'              => 0,
        'File::Basename'            => 0,
        'File::Find'                => 1.01,                 
        'File::Spec'                => 0,
        'Getopt::Long'              => 0,
        'IO::File'                  => 1.14,
        'Readonly'                  => 1.03,
        'PPI'                       => 1.113,
        'Statistics::Basic::StdDev' => 0,
        'Statistics::Basic::Mean'   => 0,
        'Statistics::Basic::Median' => 0,
        'Pod::Usage'                => 0,
        'Test::Compile'             => 0,
        'Test::Pod'                 => 1.00,
        'Test::Pod::Coverage'       => 1.04,
    },
);
