#!/usr/bin/perl
# $File: //depot/libOurNet/BBSAgent/Makefile.PL $ $Author: autrijus $
# $Revision: #3 $ $Change: 6077 $ $DateTime: 2003/05/25 10:48:47 $

use 5.005;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Scriptable telnet-based virtual users',
    NAME            => 'OurNet::BBSAgent',
    VERSION_FROM    => 'BBSAgent.pm',
    DISTNAME        => 'OurNet-BBSAgent',
    BINARY_LOCATION => 'x86/OurNet-BBSAgent.tar.gz',
    PREREQ_PM	    => {
	'Net::Telnet'	=> '3.02',	# BBSAgent
	'Test::More'	=> '0.32',	# test script
    },
    dist            => {
	COMPRESS    => 'gzip -9',
	SUFFIX      => '.gz',
    }
);
