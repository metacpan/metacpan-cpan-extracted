#!/usr/bin/perl
# $Id$
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	'NAME'		=> 'Net::RDAP',
	'VERSION_FROM'	=> 'lib/Net/RDAP.pm',
	'PREREQ_PM'	=> {
		'DateTime::Format::ISO8601'	=> 0,
		'File::Basename'		=> 0,
		'File::Slurp'			=> 0,
		'File::Spec'			=> 0,
		'File::Temp'			=> 0,
		'File::stat'			=> 0,
		'HTTP::Request::Common'		=> 0,
		'JSON'				=> 0,
		'LWP::Protocol::https'		=> 0,
		'LWP::UserAgent'		=> 0,
		'MIME::Type'			=> 0,
		'Mozilla::CA'			=> 0,
		'Net::ASN'			=> 0,
		'Net::DNS::Domain'		=> 0,
		'Net::DNS::RR::DNSKEY'		=> 0,
		'Net::DNS::RR::DS'		=> 0,
		'Net::IP'			=> 0,
		'URI'				=> 0,
		'vCard'				=> 0,
	},
);
