########################################################################
# File:     Makefile.PL
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id: Makefile.PL,v 1.1 2000/02/10 00:16:38 winters Exp $
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

$| = 1;

### Distribution Section -- from Graham Barr ###

$DISTNAME = 'Persistent::DBI';
$VERSION_FROM = 'lib/Persistent/DBI.pm';
$AUTHOR = 'David Winters <winters@bigsnow.org>';
($ABSTRACT = <<"EDQ") =~ s/\n/\\n/g;
Persistent is a framework of classes that makes it easier to
store and retrieve Perl objects to/from various types of data stores
using a common programming interface.  Persistent::DBI is the abstract
class that is required by all database (DBI) implemented Persistent
classes, such as Persistent::MySQL, Persistent::Oracle,
Persistent::Sybase, and Persistent::mSQL.
EDQ

### Check for required modules -- from Graham Barr ###

print "\nChecking for installed modules\n\n";

my $missing = 0;

check_module('Persistent::Base', 0.50) or print <<"EDQ","\n";
Persistent::Base version 0.50 or later is required for this module
EDQ

check_module('DBI', 1.13) or print <<"EDQ","\n";
DBI version 1.13 or later is required for this module
EDQ

die "\n",<<"EDQ","\n" if $missing;
****************************************************************************
You are missing some modules that are needed for these modules
to work correctly. Read the above messages and download any required
modules from http://www.perl.com/CPAN
****************************************************************************
EDQ

### Write the makefile ###

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

######################################################################
# Subroutines
######################################################################

### Check for the presence of modules/versions ###
### from Graham Barr's code -- Thanks! ###
sub check_module {
  my($module, $version) = @_;
  print substr("$module ............................",0,30);
  my $ok = eval {
    my $file = $module;
    $file =~ s#::#/#g;
    require $file . ".pm";
    $module->VERSION($version) if defined $version;
    1;
  };
  $missing++ unless $ok;
  print $ok ? "ok\n" : "** FAILED **\n$@\n";
  $ok;
}
