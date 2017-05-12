use strict;
use warnings;
use 5.006001;
use ExtUtils::MakeMaker;
my %build_reqs = (
	'ExtUtils::MakeMaker' => 6.55,	#	See below.
        'Test::More' => 0,		#	0.86
        'Test::Harness' => 2.03,	#	Need proper TODO support.
	'IO::CaptureOutput' => 0,	#	1.1
	'Test::Differences' => 0,	#	0.4801
);

WriteMakefile(
    NAME                => 'Pod::Advent',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Pod/Advent.pm',
    ABSTRACT_FROM       => 'lib/Pod/Advent.pm',
    EXE_FILES           => [ 'bin/pod2advent' ],
    BUILD_REQUIRES      => \%build_reqs,
    PREREQ_PM => {
					# {newest as of 12/2008; should eventually become min vers}
	'Pod::Simple' => 3.06,		# Need 'feature to parse additional text after =begin target as a block title' added in v3.06
	'Perl::Tidy' => 20101217,	#	20021130 fails; 20090616 gives extra stderr.
	'File::Basename' => 0,		#	2.74
	'Cwd' => 0,			#	3.29
	'HTML::Entities' => 0,		#	3.64
#	'Text::Aspell' => 0,		#	0.09	# Optional; Too hard to install (e.g. missing aspell.h; win32 compiling; etc) to mandate.

	# BUILD_REQUIRES support was added in v6.55_01
        ( $ExtUtils::MakeMaker::VERSION < 6.55 ? %build_reqs : () ),
    },
    ( $ExtUtils::MakeMaker::VERSION >= 6.48
        # MIN_PERL_VERSION support was added in v6.47_01
	? (MIN_PERL_VERSION    => '5.6.1')
	: ()
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Pod-Advent-*' },
);
