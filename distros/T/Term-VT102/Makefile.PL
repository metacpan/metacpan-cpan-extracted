#!/usr/bin/perl -w
#
# Call MakeMaker and get it to build the Makefile.
#

use lib "lib";
use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
	'NAME'         => 'Term::VT102',
	'VERSION_FROM' => 'VT102.pm',
	'ABSTRACT'     => 'emulate a DEC VT102 terminal',
	'AUTHOR'       => 'Andrew Wood <andrew dot wood at ivarch dot com>'
);

# EOF
