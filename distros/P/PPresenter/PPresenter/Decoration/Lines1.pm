# Copyright (C) 2000-2002, Free Software Foundation FSF.
# This module was created mainly as demonstration how to work with
# the flexability offered by the Decoration module.

package PPresenter::Decoration::Lines1;

use strict;
use PPresenter::Decoration;
use base 'PPresenter::Decoration';

use constant ObjDefaults =>
{ -name                => 'lines1'
, -aliases             => [ 'Lines1' ]
, -pageLogo            => undef
, -pageLogoSpacing     => 0.01

, -decorationLineWidth => 2
, -decorationLineColor => undef
};

my $general_tag = __PACKAGE__;

sub prepare($$$)
{   my ($deco, $show, $slide, $view) = @_;
    $deco->SUPER::prepare($show, $slide, $view);

    my $logo    = $deco->{-pageLogo};
    my $logoimg = (ref $logo && $logo->isa('PPresenter::Image')) ? $logo
                : defined $logo ? $deco->createLogoImage($view, $logo)
                : die "pageLogo is obligatory for decoration $deco.\n";

    my $decodata= $show->decodata($view);
    my $showimg = $decodata->{showing_logo};
    return $deco if defined $showimg && "$showimg" eq "$logoimg";

    # New logo shows-up.
    $deco->cleanup($show, $slide, $view);
    my ($imgw, $imgh) = $logoimg->dimensions($view->viewport);
    my ($w, $h)       = $view->canvasDimensions;
    my $space         = $deco->{-pageLogoSpacing};
    $decodata->{showing_logo} = $logoimg;
    $logoimg->show($view->viewport, $view->canvas, $space*$w, $space*$h
    , -anchor => 'nw', -tag => $general_tag);

    @$decodata{'sx', 'sy', 'vertx'}
        = ($space*$h, (2*$space)*$h+$imgh, $space*$w+int($imgw/3));

    $deco->{-titleBounds} = [ 2*$space+$imgw/$w, 0.05
                            , 0.97, $space+$deco->{-defaultTitlebarHeight} ]
        unless defined $deco->{-titleBounds};

    $deco->{-mainBounds}  = [ $space + $imgw/2/$w
          , $space+$deco->{-defaultTitlebarHeight} + $deco->{-areaSeparation}
          , @{$deco->{-defaultBounds}}[2,3]
          ] unless defined $deco->{-mainBounds};
    $deco;
}

sub createLogoImage($$)
{   my ($deco, $view, $file) = @_;

    my $logo = $view->image
    ( -file    => $file
    , -resize  => 0
    );
    die "Unable to find image $file\n" unless $logo;

    $logo->prepare($view->viewport, $view->canvas);
    $logo;
}

sub createPart($$$$$$)
{   my ($deco, $show, $slide, $view, $part, $parttag, $dx) = @_;
    $deco->SUPER::createPart($show, $slide, $view, $part, $parttag, $dx);

    if($part eq 'footer')
    {    my $decodata = $show->decodata($view);
         my $canvas   = $view->canvas;
         my ($x0, $y0, $x1, $y1) = $canvas->bbox($parttag);
         my $liney    = int( ($y1+$y0)/2 );
         my $width    = $deco->{-decorationLineWidth};
         my $color    = $deco->{-decorationLineColor}
                     || $deco->color($view, 'FGCOLOR');

         my ($sx, $sy, $vertx)= @$decodata{'sx', 'sy', 'vertx'};

         $canvas->createLine
         ( $sx, $sy, $vertx, $sy, $vertx, $liney, $x0-$dx-5, $liney
         , -width => $width
         , -fill  => $color
         , -tag   => $general_tag
         );

         $canvas->createLine($x1-$dx+5, $liney, $canvas->width-5, $liney
         , -width => $width
         , -fill  => $color
         , -tag   => $general_tag
         );
    }

    $deco;
}

sub finish($$$)
{   my ($deco, $show, $slide, $view) = @_;
    $deco->SUPER::finish($show, $slide, $view);

    $view->canvas->configure
        ( -background => $deco->color($view,'BGCOLOR')
        );

    my $decodata= $show->decodata($view);
    my $showimg = $decodata->{showing_logo};

    $deco;
}

sub cleanup($$$)
{   my ($deco, $show, $slide, $view) = @_;
    $deco->SUPER::cleanup($show, $slide, $view);

    $view->canvas->delete($general_tag);
    $deco;
}

1;
