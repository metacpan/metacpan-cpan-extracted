#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::Rackspace::CloudFies',
    VERSION_FROM => 'lib/Net/Rackspace/CloudFiles.pm',
    AUTHOR       => 'William Wolf <throughnothing@gmail.com>, Naveed Massjouni <ironcamel@gmail.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
		'Digest::MD5'                  => '0',
		'HTTP::Request'                => '0',
		'LWP::UserAgent'               => '0',
		'Date::Parse'                  => '0',
		'Test::Unit::TestCase'         => '0',
		'Moose'				        => '0'
    }
);
