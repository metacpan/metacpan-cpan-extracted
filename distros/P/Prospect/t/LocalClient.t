#!/usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: LocalClient.t
# PURPOSE: test script for the LocalClient, Options, Thread, Init, File classes.
#          used in conjunction with Makefile.PL to test installation
#
# $Id: LocalClient.t,v 1.2 2003/11/07 18:41:58 cavs Exp $
#-------------------------------------------------------------------------------

use Prospect::Options;
use Prospect::LocalClient;
use Prospect::Thread;
use Prospect::Init;
use Prospect::File;
use Bio::Structure::IO;
use Bio::SeqIO;
use Test::More;
use warnings;
use strict;
use vars qw( $VERSION );

$VERSION = sprintf( "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/ );

plan tests => 72;

my $fn = 't/SOMA_HUMAN.fa';
ok( -f $fn, "$fn valid" );

my $xfn = 't/SOMA_HUMAN.xml';
ok( -f $xfn, "$xfn valid" );

my @tnames = qw( 1alu 1bgc 1lki 1huw 1f6fa 1cnt3 1ax8 1evsa 1f45b );

ok( my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $fn ), "Bio::SeqIO::new('-file' => $fn)");

my $po = new Prospect::Options( ncpus=>1,seq=>1, svm=>1, global_local=>1, templates=>\@tnames );
ok( defined $po && ref($po) && $po->isa('Prospect::Options'), 'Prospect::Options::new' );

my $lc = new Prospect::LocalClient( {options=>$po} );
ok( defined $lc && ref($lc) && $lc->isa('Prospect::LocalClient'), 'Prospect::LocalClient::new' );

my $s = $in->next_seq();
ok( my $xml = $lc->xml( $s ),        'Prospect::LocalClient::xml' );
ok( my @threads = $lc->thread( $s ), 'Prospect::LocalClient::thread' );

# get threads from xml file.  compare some Threads from LocalClient and xml file.
my $pf = new Prospect::File;
ok( defined $pf && ref($pf) && $pf->isa('Prospect::File'), 'Prospect::File::new()' );
ok( $pf->open( "<$xfn" ), "open $xfn" );
my $cnt=0;
while( my $t = $pf->next_thread() ) {
	ok( defined $t && ref($t) && $t->isa('Prospect::Thread'), 'Prospect::Thread::new()' );

	ok( $threads[$cnt]->tname eq $t->tname,         "Prospect::LocalClient::tname eq " . $t->tname );
	ok( $threads[$cnt]->raw_score eq $t->raw_score, "Prospect::LocalClient::raw_score eq " . $t->raw_score );

	my $pdbf = "$Prospect::Init::PROCESSED_PDB_PATH/".$t->tname.".pdb";
	ok( defined $pdbf && -r $pdbf, "$pdbf valid" );

	my $pdb  = Bio::Structure::IO->new(-file => $pdbf, '-format' => 'pdb');
	ok( defined $pdb && ref($pdb) && $pdb->isa('Bio::Structure::IO'), 'Bio::Structure::IO' );

	ok( my $struc = $pdb->next_structure(), 'Bio::Structure::IO::next_structure()' );
	ok( $t->output_rasmol_script($struc), 'Prospect::Thread::output_rasmol_script' );

	$cnt++;
}
