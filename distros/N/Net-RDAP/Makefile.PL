#!/usr/bin/perl
# $Id$
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	'NAME'		=> 'Net::RDAP',
	'VERSION_FROM'	=> 'lib/Net/RDAP.pm',
	'PREREQ_PM'	=> {
		'File::Basename'	=> 0,
		'File::Slurp'		=> 0,
		'File::Spec'		=> 0,
		'File::stat'		=> 0,
		'HTTP::Request::Common'	=> 0,
		'JSON'			=> 0,
		'LWP::Protocol::https'	=> 0,
		'LWP::UserAgent'	=> 0,
		'Mozilla::CA'		=> 0,
		'URI'			=> 0,
	},
);
