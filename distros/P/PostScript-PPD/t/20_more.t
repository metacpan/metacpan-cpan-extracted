#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
BEGIN { chdir "$FindBin::Dir/.." }

use Test::More ( tests => 14 );
use Data::Dumper;



use t::ChkUtil;
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

