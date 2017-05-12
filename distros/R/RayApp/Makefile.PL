
use strict;
use 5.008001;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'RayApp',
	VERSION_FROM => 'lib/RayApp.pm',
	PREREQ_PM => {
		'XML::LibXML' => 0,
		'XML::LibXSLT' => 0,
		'IO::ScalarArray' => 0,
		'CGI' => 0,
		'Test::More' => 0,
		'POSIX' => 0,
		'IPC::Open3' => 0,
		'Encode' => 0,
		'warnings' => 0,
		'strict' => 0,
	},
	PREREQ_FATAL => 1,
	PL_FILES => { 'bin/rayapp_cgi_wrapper.PL' => 'bin/rayapp_cgi_wrapper', },
        EXE_FILES => [ 'bin/rayapp_cgi_wrapper' ],
	dist => {
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ..',
	},
	clean => {
		FILES => 'bin/rayapp_cgi_wrapper',
	},
);

