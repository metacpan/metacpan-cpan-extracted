#!/usr/bin/perl

use strict;
use warnings;

use Test::More ( tests => 16 );

use FindBin;
use File::Path qw(make_path remove_tree);
use File::Spec;
use Imager;
use PDF::API2;

sub DEBUG () { 0 }

use_ok('PDF::API2::Resource::XObject::Image::Imager');


my $dir = $FindBin::Bin;
my $in = File::Spec->catdir( $dir, 'resources' );
my $out = File::Spec->catdir( $dir, '..', 'out' );
# $out = File::Spec->canonpath( $out );

make_path( $out ) unless -d $out;

my $pdf = PDF::API2->new;

my $font = $pdf->corefont('Helvetica-Bold');

my $img = Imager->new;

for my $name ( qw( 1x1.png test-rgba.png palette.png graya.png bilevel.png rgb8i.png t102.png ) ) {
    DEBUG and diag( $name );

    my $file = File::Spec->catfile( $in, $name );
    $img->read( file=>$file ) or die "Unable to read image: ".$img->errstr;

    my $xo = $pdf->imager( $img );
    ok( $xo, "Import $name" );

    my $iw = $img->getwidth;
    my $ih = $img->getheight;

    my $page = $pdf->page( 0 );
    $page->mediabox( "Letter" );

    my @box = $page->get_mediabox;
    my $pw  = $box[2];
    my $ph = $box[3];
    DEBUG and diag( "pw=$pw ph=$ph" );
    DEBUG and diag( "iw=$iw ih=$ih" );

    my $scale = 1;
    if( $iw > $pw ) {
        $scale = $pw/$iw;
    }
    elsif( $ih > $ph ) {
        $scale = $ph/$ih;
    }
    $ih *= $scale;
    $iw *= $scale;

    my $x = ($pw-$iw)/2;
    my $y = ($ph-$ih)/2;

    DEBUG and diag( "($x,$y) $scale" );

    my $gfx = $page->gfx;
    $gfx->image( $xo, $x, $y, $scale );
    pass( "Added $name" );

    my $text = $page->text();
    $text->font($font, 20);
    $text->translate(8, 8);
    $text->text( $name );
}

my $file = File::Spec->catfile( $out, "import.pdf" );
$pdf->save( $file );
pass( "Wrote $file" );

