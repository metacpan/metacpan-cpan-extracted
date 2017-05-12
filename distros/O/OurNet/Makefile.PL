#!/usr/bin/perl
# $File: //depot/libOurNet/Makefile.PL $ $Author: autrijus $
# $Revision: #14 $ $Change: 2112 $ $DateTime: 2001/10/17 05:42:55 $

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Interface to BBS-based groupware platforms',
    NAME            => 'OurNet',
    DISTNAME        => 'OurNet',
    BINARY_LOCATION => 'x86/OurNet.tar.gz',
    VERSION_FROM    => 'OurNet.pm',

    PREREQ_PM       => {
	# prerequisites
        'ExtUtils::AutoInstall'	=> '0.01',

	# the BBS Toolkit
        'OurNet::BBS'		=> '1.62',
        'OurNet::BBSAgent'	=> '1.58',
        'OurNet::BBSApp::Sync'	=> '0.87',

	# the Query Toolkit
        'OurNet::Query'		=> '0.01',
        'OurNet::Site'		=> '0.01',
        'OurNet::Template'	=> '0.01',
        'OurNet::FuzzyIndex'	=> '0.01',
        'OurNet::ChatBot'	=> '0.01',

	# 'OurNet::BBSApp'	=> '1.60', # not ready
	# 'Slash::OurNet'	=> '0.01', # not ready
    },

    dist            => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
    }
);

