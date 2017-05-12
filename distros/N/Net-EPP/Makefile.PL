#!/usr/bin/perl
# $Id$
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	'NAME'		=> 'Net::EPP',
	'VERSION_FROM'	=> 'lib/Net/EPP.pm',
	'PREREQ_PM'	=> {
		'IO::Socket::SSL'	=> 0,
		'XML::LibXML'		=> 0,
		'Time::HiRes'		=> 0,
		'Digest::SHA'		=> 0,
	},
);
