use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
 	NAME			=> 'RundeckAPI',
	AUTHOR			=> q{Xavier Humbert <xavier.humbert@ac-nancy-metz.fr>},
	VERSION_FROM	=> 'lib/RundeckAPI.pm',
	ABSTRACT		=> 'Queries Rundeck\'s REST API',
	LICENSE			=> 'GPL',
	PL_FILES		=> {'script/main.pl'},
	PREREQ_PM => {
		'File::Basename'		=> 2.77,
		'LWP::UserAgent'		=> 5.833,
		'HTTP::Cookies'			=> 5.833,
		'REST::Client'			=> 272,
		'Scalar::List::Utils'	=> 1.27,
		'JSON'					=> 2.15
	},
	TEST_REQUIRES => {
			'Test::More'		=> 0.98,
	},
);

=pod
History
Updated version to match those in RHEL6
=cut
