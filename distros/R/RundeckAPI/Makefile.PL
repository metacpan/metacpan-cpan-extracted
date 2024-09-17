#~ use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
 	NAME			=> 'RundeckAPI',
	AUTHOR			=> q{Xavier Humbert <xavier.humbert@ac-nancy-metz.fr>},
	VERSION_FROM	=> 'lib/RundeckAPI.pm',
	ABSTRACT		=> 'Queries Rundeck REST API',
	LICENSE			=> 'GPL',
	PL_FILES		=> {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
	PREREQ_PM => {
		'File::Basename'		=> 2.85,
		'LWP::UserAgent'		=> 5.833,
		'HTTP::Cookies'			=> 5.833,
		'REST::Client'			=> 273,
		'Scalar::Util'			=> 1.27,
		'JSON'					=> 2.97,
	},
	TEST_REQUIRES => {
			'Test::More'		=> 1.300,
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RundeckAPI-*' },
);

=pod
History
Updated version to match those in RHEL6
=cut
