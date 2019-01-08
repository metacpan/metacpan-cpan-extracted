use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
	'Error::Helper'=>'1.0.0',
	'Proc::ProcessTable'=>'0.53',
	'Term::ANSIColor'=>'4.06',
	'Text::Table'=>'1.133',
	'Term::Size'=>'0.207',
	);

WriteMakefile(
    NAME             => 'Proc::ProcessTable::Colorizer',
    AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
    VERSION_FROM     => 'lib/Proc/ProcessTable/Colorizer.pm',
    ABSTRACT_FROM    => 'lib/Proc/ProcessTable/Colorizer.pm',
    LICENSE          => 'freebsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
	INST_SCRIPT => 'bin',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => \%PREREQ_PM,
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Proc-ProcessTable-Colorizer-*' },
);
