########################################################################
# File:     Makefile.PL
# Author:   David Winters <winters@bigsnow.org>
# RCS:      $Id$
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

$DISTNAME = 'Persistent::LDAP';
$VERSION_FROM = 'lib/Persistent/LDAP.pm';
$AUTHOR = 'David Winters <winters@bigsnow.org>';
($ABSTRACT = <<"EDQ") =~ s/\n/\\n/g;
Persistent is a framework of classes that makes it easier to
store and retrieve Perl objects to/from various types of data stores
using a common programming interface.  Persistent::LDAP is a
subclass that implements the Persistent interface using a LDAP
directory as the data store.  This class inherits from the Persistent::Base
class and so requires it.
EDQ

### Check for required modules -- from Graham Barr ###

print "\nChecking for installed modules\n\n";

my $missing = 0;

check_module('Persistent::Base', 0.50) or print <<"EDQ","\n";
Persistent::Base version 0.50 or later is required for this module
EDQ

check_module('Net::LDAP', 0.13) or print <<"EDQ","\n";
Net::LDAP version 0.13 or later is required for this module
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
