#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More ( tests => 24 );
use Data::Dumper;

use t::ChkUtil;
dualvar_or_skip 24;

use_ok( 'PostScript::PPD' );

my $ppd = PostScript::PPD->new;

ok( $ppd, "Created an object" );

#####
$ppd->load( "t/ppd/pcl-4l.ppd.gz" );
pass( "Loaded PPD" );

my $G = $ppd->Group( 'STP' );
ok( $G, "Group STP" );
my $ui = $G->get( 'UI.stpImageType' );
ok( $ui, "UI stpImageType" )
        or die $G->Dump;
my $it = $ui->stpImageType;
ok( $it, "stpImageType" )
        or die $ui->Dump;

my $l = $it->list;
is_deeply( $l, [ qw( LineArt SolidTone Continuous ) ], "LineArt was parsed" )
    or die $it->Dump;

my $la = $it->LineArt;

# warn $la->Dump;
is( $la->name, 'LineArt', " ... name" );
is( $la->text, '"Line Art"', " ... text" );
is( $la->honk, undef );


##########################################
$ppd->load( "t/ppd/LJ4L.ppd" );
pass( "Loaded LJ 4L ppd" );

$G = $ppd->Group( 'Adjustment' );
ok( $G, "Group Adjustment" );
$ui = $G->get( 'UI.HalftoningAlgorithm' );
ok( $ui, "UI HalftoningAlgorithm" );
my $ha = $ui->HalftoningAlgorithm;
ok( $ha, "Got HalftoningAlgorithm" );

######
my $wts = $ha->get( 'WTS' );
ok( $wts, "Read WTS" )
        or die Dumper $ha;
is( "$wts", q,
      << /UseWTS true >> setuserparams
      <<
        /AccurateScreens true
        /HalftoneType 1
        /HalftoneName (Round Dot Screen)
        /SpotFunction { 180 mul cos exch 180 mul cos add 2 div}
        /Frequency 137
        /Angle 37
      >> sethalftone
    ,, " ... value" ) or die $wts->Dump; 

my $A = $ha->get( 'Accurate' );
ok( $A, "Read Accurate" )
        or die $ha->Dump;
is( "$A", q,
      << /UseWTS false >> setuserparams
      <<
        /AccurateScreens true
        /HalftoneType 1
        /HalftoneName (Round Dot Screen)
        /SpotFunction { 180 mul cos exch 180 mul cos add 2 div}
        /Frequency 137
        /Angle 37
      >> sethalftone
    ,, " ... value" ) or die $A->Dump; 

##########################################
$ppd->load( "t/ppd/lj4515.ppd" );
pass( "Loaded LJ 4L ppd" );

$ppd->load( "t/ppd/stlin.ppd" );
pass( "Loaded Lexmark T641 ppd" );

my $oid = $ppd->OIDOptDuplex;
isa_ok( $oid, "PostScript::PPD::Subkey", "OID promoted to subkey" ) or die Dumper $oid;
is( $oid->value, ".1.3.6.1.2.1.43.13.4.1.10.1.2", " ... value" );

my $proc = $ppd->DefaultScreenProc;
is( $proc, 'Dot', "* DefaultScreenProc" );

my $ps = $ppd->FontList;
is( $ps, "
\tsave
\t2 dict begin
\t\t/sv exch def
\t\t/str 128 string def
\t\tFontDirectory { pop == } bind forall flush
\t\t/filenameforall where
\t\t{ pop save (fonts/*)
\t\t\t{ dup length 6 sub 6 exch getinterval cvn == } bind
\t\t\tstr filenameforall flush restore
\t\t} if
\t\t(*) = flush
\t\tsv
\tend
\trestore", "Multiline" ) or warn "'$ps'";
