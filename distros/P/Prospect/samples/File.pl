#!/usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: File.pl
# PURPOSE: test script for the File object
# USAGE: File.pl prospect-xml-file
#
# $Id: File.pl,v 1.6 2003/11/04 01:01:33 cavs Exp $
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Prospect::File;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/ );


my $fn = shift;
defined $fn
  || die("USAGE: File.pl prospect-xml-file\n");

my $pf = new Prospect::File;
$pf->open( "<$fn" )
  || die("$fn: $!\n");

while( my $t = $pf->next_thread() ) {
  printf("%s->%s   raw=%d mut=%d pair=%d\n",
     $t->qname(), $t->tname(),
     $t->raw_score(), $t->mutation_score(), $t->pair_score() );
  print $t->alignment();
}
