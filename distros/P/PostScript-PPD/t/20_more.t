#!/usr/bin/perl

use strict;
use warnings;

#use FindBin;
#BEGIN { chdir "$FindBin::Dir/.." }
use lib "t/lib";

use Test::More ( tests => 23 );
use Data::Dump qw( pp );



use ChkUtil;
dualvar_or_skip 14;

use_ok( 'PostScript::PPD' );

my $ppd = PostScript::PPD->new;

ok( $ppd, "Created an object" );

#####
$ppd->load( "t/ppd/HP-LaserJet_4L-hpijs.ppd" );
pass( "Loaded HP LasterJet 4L ppd" );
is( $ppd->Manufacturer, 'HP', " ... Manufacturer" );
is( $ppd->ModelName, "HP LaserJet 4L", " ... ModelName" );

#####
$ppd->load( "t/ppd/Generic-PCL_5_Printer-gimp-print-ijs.ppd" );
pass( "Loaded Generic PCL 5 ppd" );
is( $ppd->Manufacturer, 'Generic', " ... Manufacturer" );
is( $ppd->ModelName, "Generic PCL 5 Printer", " ... ModelName" );

#####
$ppd->load( "t/ppd/postscript.ppd.gz" );
pass( "Loaded Generic PostScript ppd" );
is( $ppd->Manufacturer, 'Postscript', " ... Manufacturer" );
is( $ppd->ModelName, "Generic postscript printer", " ... ModelName" );

#####
$ppd->load( "t/ppd/LJ4L.ppd" );
pass( "Loaded LJ 4L ppd" );
is( $ppd->Manufacturer, 'HP', " ... Manufacturer" );
is( $ppd->ModelName, "HP LaserJet 4L", " ... ModelName" );

#####
$ppd->load( "t/ppd/hwel.ppd" );
pass( "Loaded Lexmark MB2200 Series ppd" );
is( $ppd->Manufacturer, 'Lexmark', " ... Manufacturer" );
is( $ppd->ModelName, "Lexmark MB2200 Series", " ... ModelName" );

my $custom = $ppd->Group( 'JCL' )->get( 'CustomPnH' )->get( "True" )->value;
is( $custom, q(@PJL SET JOBNAME = GETMYJOBNAME
@PJL SET USERNAME = GEYMYUSERNAME
@PJL SET HOLD = ON
@PJL SET HOLDTYPE = PRIVATE
@PJL SET HOLDKEY = "\1"
@PJL SET QTY = GETMYCOPIES<0A>), qq(Parsed "" on a line) ); # or die pp $custom;

#####
$ppd->load( "t/ppd/Ricoh-PDF_Printer-PDF.ppd" );
pass( "Loaded Ricoh MS330 Series ppd" );
is( $ppd->Manufacturer, 'Ricoh', " ... Manufacturer" );
is( $ppd->ModelName, "Ricoh PDF Printer", " ... ModelName" );

my $G = $ppd->Group( "General" );
ok( $G, "Got General" );
my $UI = $G->UI( "N-up" );
ok( $UI, "Got General/N-up" ) or die pp $G;
