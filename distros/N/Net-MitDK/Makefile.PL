use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME           => 'Net::MitDK',
	AUTHOR         => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM  => 'lib/Net/MitDK.pm',
	VERSION_FROM   => 'lib/Net/MitDK.pm',
        EXE_FILES      => [
		map { "bin/mitdk$_" } qw(2pop -dump -authenticate -renew-lease -install-win32),
	],
        LICENSE        => 'freebsd',
	PREREQ_PM      => {
		'LWP'             => 0,
		'IO::Lambda'      => 1.32,
		'DateTime'        => 0,
		'MIME::Entity'    => 0,
		'MIME::Base64'    => 0,
		'JSON::XS'        => 0,
		'Getopt::Long'    => 0,
		'Digest::SHA'     => 0,
		'IO::Socket::SSL' => 0,
	},
	MIN_PERL_VERSION  => 5.018,
	META_MERGE     => {
		resources => {
			repository => 'http://github.com/dk/Net-MitDK'
		},
	},
);
