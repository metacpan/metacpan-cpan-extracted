########################################################################
# File:     Makefile.PL
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: Makefile.PL,v 1.4 2000/02/09 23:30:56 winters Exp winters $
#
# Perl script that generates a makefile for a CPAN module.
#
# NOTE: Much of this script came from one of Graham Barr's scripts.
#       Thanks, man!
#
# Copyright (c) 1998-2000 David Winters.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
########################################################################

use 5.004;
use ExtUtils::MakeMaker;

### Distribution Section -- from Graham Barr ###

$DISTNAME = 'Persistent::Base';
$VERSION_FROM = 'lib/Persistent/Base.pm';
$AUTHOR = 'David Winters <winters@bigsnow.org>';
($ABSTRACT = <<"EDQ") =~ s/\n/\\n/g;
Persistent is a framework of classes that makes it easier to
store and retrieve Perl objects to/from various types of data stores
using a common programming interface.  Persistent::Base is the base
package and includes classes that implement persistence using text
and DBM files.  There are other classes that implement persistence
using databases and LDAP directories.
EDQ

### Write the makefile -- from Graham Barr ###

WriteMakefile(
	      'NAME'	     => $DISTNAME,
	      'VERSION_FROM' => $VERSION_FROM, # finds $VERSION
	      'AUTHOR'       => $AUTHOR,
	      'ABSTRACT'     => $ABSTRACT,
	      'dist'         => {
				 'COMPRESS' => 'gzip -9f',
				 'SUFFIX'   => 'gz',
				 'ZIP'      =>'/usr/bin/zip',
				 'ZIPFLAGS' =>'-rl'
				},
	      'clean'        => {
				 FILES => 'temp'
				},
	     );
