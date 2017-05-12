#!/usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: Align.pl
# PURPOSE: test script for the Align object
# USAGE: Align.pl sequence-file
#
# $Id: Align.pl,v 1.6 2003/11/04 01:01:33 cavs Exp $
#-------------------------------------------------------------------------------

use Prospect::Options;
use Prospect::LocalClient;
use Prospect::Align;
use Bio::SeqIO;
use warnings;
use strict;

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/ );


die( "USAGE: Align.pl sequence-file\n" ) if $#ARGV != 0;

my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $ARGV[0] );
my $po = new Prospect::Options( seq=>1, svm=>1, global_local=>1,
                 templates=>[qw(1bgc 1alu)] );
my $pf = new Prospect::LocalClient( {options=>$po} );

while ( my $s = $in->next_seq() ) {
  my @threads = $pf->thread( $s ); 
  my $pa = new Prospect::Align( -debug=>0,-threads => \@threads );
  print $pa->get_alignment(-format=>'html');
}
