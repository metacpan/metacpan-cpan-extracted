#!/usr/bin/env perl
# -*- mode: perl; coding: iso-8859-1 -*-
# Author: Peter Corlett
# Contact: abuse@cabal.org.uk
# Revision: $Revision$
# Date: $Date$
# Copyright: (c) 2005 Peter Corlett - All Rights Reserved

require 5.8.1;
use warnings;
use strict;
use vars qw( $VERSION );

# $Id: Makefile.PL 35 2005-09-27 13:27:28Z abuse $
$VERSION = do { my @r=(q$Revision: 35 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use ExtUtils::MakeMaker;

WriteMakefile(
	      ABSTRACT => 'Server-side SNMP modules',
	      NAME     => 'SNMP::Server::Logtail',
	      DISTNAME => 'SNMP-Server',
	      VERSION  => '1.005',
	      PREREQ_PM=> { threads => 0 },
	     );
