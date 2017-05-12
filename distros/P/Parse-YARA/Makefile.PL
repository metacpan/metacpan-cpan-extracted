use strict;
use warnings;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Parse::YARA',
    AUTHOR            => 'Leigh Thompson <moofu@cpan.org>',
    VERSION_FROM      => 'lib/Parse/YARA.pm',
    ABSTRACT_FROM     => 'lib/Parse/YARA.pm',
    LICENSE           => 'Apache_2_0',
    META_MERGE        => {
                            'resources' => {
                                            'repository'  =>  'https://github.com/moofusecurity/Parse-YARA',
                            },
    },
    MIN_PERL_VERSION  => '5.005',
    PREREQ_PM         => {
							'Carp' => 0,
							'Tie::IxHash' => 0,
							'File::Basename' => 0,
                            'Test::More' => 0
    },
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean             => { FILES => 'Parse-YARA-*' },
);
