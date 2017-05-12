#!/usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: Exceptions.pl
# PURPOSE: test script for the Exceptions object
# USAGE: Exceptions.pl
#
# $Id: Exception.pl,v 1.6 2003/11/04 01:01:33 cavs Exp $
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Prospect::Exceptions;

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/ );


try { nested_thrower('jomama'); }
catch CBT::Exception with { 
  print "caught CBT::Exception\n"; 
};


sub thrower
  { throw Prospect::Exception( "you goofed with thrower($_[0])"); }

sub nested_thrower { thrower(@_) }

