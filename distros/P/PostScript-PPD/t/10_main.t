#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/..";

use Test::More ( tests => 68 );
use Data::Dumper;

use t::ChkUtil;
dualvar_or_skip 68;

use_ok( 'PostScript::PPD' );

my $ppd = PostScript::PPD->new;

ok( $ppd, "Created an object" );

$ppd->load( "t/ppd/HP-LaserJet_4L-hpijs.ppd" );

ok( $ppd, "Loaded HP LasterJet 4L ppd" );

# warn Dumper $ppd;
is( $ppd->Manufacturer, "HP", " ... Manufacturer" );
is( $ppd->ModelName, "HP LaserJet 4L", " ... ModelName" );
ok( !$ppd->ColorDevice, " ... not ColourDevice" );
ok( $ppd->cupsManualCopies, " ... cupsManualCopies" );

my $ps = $ppd->PSVersion;
is_deeply( $ps, [
  '(3010.000) 550',
  '(3010.000) 651',
  '(3010.000) 652',
  '(3010.000) 653',
  '(3010.000) 704',
  '(3010.000) 705',
  '(3010.000) 800'
], " ... PSVersion" )
        or die Dumper $ps;

$ps = $ppd->CustomPageSize( 'True' );
is( $ps, "pop pop pop pop pop\n%% FoomaticRIPOptionSetting: PageSize=Custom", 
    " ... CustomPageSize/True" )
        or die Dumper $ps;

my $cmd = $ppd->FoomaticRIPCommandLine;
is( $cmd, "gs -q -dBATCH -dPARANOIDSAFER -dQUIET -dNOPAUSE -sDEVICE=ijs -sIjsServer=hpijs%A%B%C -dIjsUseOutputFD%Z -sOutputFile=- -", 
            " ... FoomaticRIPCommandLine" );

#####
my $G = $ppd->Group( 'General' );
ok( $G, "Got the general group" );
is( $G->name, "General", " ... name" );
is( $G->text, "General", " ... text" );
my $l = $G->list;
is_deeply( $l, [
  'UI.PageSize',
  'UI.PageRegion',
  'ImageableArea',
  'PaperDimension',
  'UI.InputSlot',
  'UI.Manualfeed',
  'UI.Duplex',
  'UI.Economode',
  'UI.Copies'
], " ... list" )
        or die Dumper $l;

foreach my $name ( $G->list ) {
    my $c = $G->get( $name );
    ok( $c, "     ... $name" );
}

#####
my $pd = $G->PaperDimension;
ok( $pd, "PaperDimension" );

$l = [ $pd->list ];
is_deeply( $l, [
  'Letter',
  'A4',
  'Photo',
  '3x5',
  '5x8',
  'A5',
  'A6',
  'B5JIS',
  'Env10',
  'EnvC5',
  'EnvC6',
  'EnvDL',
  'EnvISOB5',
  'EnvMonarch',
  'Executive',
  'FLSA',
  'Hagaki',
  'Legal',
  'Oufuku',
  'w558h774',
  'w612h935'
], " ... as a list" )
    or die Dumper $l;

my @list;
foreach my $name ( $pd->sorted_list ) {
    my $c = $pd->get( $name );
    ok( $c, "     ... $name" );
    push @list, join ":", $c->name, $c->text;
}

is_deeply( \@list, [
  'w558h774:16K',
  '3x5:3x5 inch index card',
  '5x8:5x8 inch index card',
  'A4:A4',
  'A5:A5',
  'A6:A6',
  'FLSA:American Foolscap',
  'B5JIS:B5 (JIS)',
  'Env10:Envelope #10',
  'EnvISOB5:Envelope B5',
  'EnvC5:Envelope C5',
  'EnvC6:Envelope C6',
  'EnvDL:Envelope DL',
  'EnvMonarch:Envelope Monarch',
  'Executive:Executive',
  'w612h935:Executive (JIS)',
  'Hagaki:Hagaki',
  'Legal:Legal',
  'Letter:Letter',
  'Oufuku:Oufuku-Hagaki',
  'Photo:Photo/4x6 inch index card'
], "All have text" )
        or die Dumper \@list;

my $p = $pd->A4;
ok( $p, "A4" );
is( $p->text, "A4", " ... text" );

$p = $pd->Photo;
ok( $p, "Photo" );
is( $p->text, "Photo/4x6 inch index card", " ... text" );

is( $pd->default, "Letter", "default" );

my $def = $pd->get( $pd->default );
ok( $def, "Got the default PaperDimension" );
is( $def->text, "Letter", " ... it's Letter" );


#####
my $groups = $ppd->Groups;
ok( ref $groups, "Groups:" );

foreach my $gname ( $ppd->Groups ) {
    my $g = $ppd->Group( $gname );
    ok( $g, "  $gname" );

    my $UIs = $g->UIs;
    ok( ref $UIs, "  $gname.UIs" );
    foreach my $name ( $g->UIs ) {
        my $ui = $g->UI( $name );
        ok( $ui, "    $gname.$name" );
    }
}
