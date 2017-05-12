###
# Copyright 1998, 1999 Massachusetts Institute of Technology
#
# Permission to use, copy, modify, distribute, and sell this software and its
# documentation for any purpose is hereby granted without fee, provided that
# the above copyright notice appear in all copies and that both that
# copyright notice and this permission notice appear in supporting
# documentation, and that the name of M.I.T. not be used in advertising or
# publicity pertaining to distribution of the software without specific,
# written prior permission.  M.I.T. makes no representations about the
# suitability of this software for any purpose.  It is provided "as is"
# without express or implied warranty.

###
# File:		Makefile.PL
# Author:	Daniel Hagerty, hag@ai.mit.edu
# Date:		Wed Mar 25 00:22:43 1998
# Description:	perl style Makefile for this frob

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME	  => 'Net::Traceroute',
	VERSION_FROM => "Traceroute.pm",
	PREREQ_PM => {
	    qw(Time::HiRes) => 0,
	},
	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz',
		      DIST_DEFAULT => 'all tardist',
		     },


);
