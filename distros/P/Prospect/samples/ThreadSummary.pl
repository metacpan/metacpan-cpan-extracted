#!/usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: ThreadSummary.pl
# PURPOSE: test script for the ThreadSummary object
# USAGE: ThreadSummary.pl prospect-xml-file
#
# $Id: ThreadSummary.pl,v 1.7 2003/11/04 01:01:34 cavs Exp $
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Prospect::File;
use Prospect::Thread;
use Prospect::ThreadSummary;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/ );


my $fn = shift;
defined $fn
  || die("USAGE: ThreadSummary.pl prospect-xml-file\n");

my $pf = new Prospect::File;
$pf->open( "<$fn" )
  || die("$fn: $!\n");

while( my $t = $pf->next_thread() ) {
  my $s = new Prospect::ThreadSummary( $t );
  printf("%s->%s   raw=%d mut=%d pair=%d\n",
     $s->qname(), $s->tname(),
     $s->raw_score(), $s->mutation_score(), $s->pair_score() );
}
