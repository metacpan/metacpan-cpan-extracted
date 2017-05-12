# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Export::Images::ImageMagick;

# This module has it's own Tk interface, but is also extended
# by more complex objects.

use strict;
use PPresenter::Export;
use base 'PPresenter::Export';

use Tk;
use Tk::Dialog;
use Image::Magick;

use constant ObjDefaults =>
{ -name        => 'Images with ImageMagick'
, -aliases     => [ 'images', 'im images', 'IM images', 'IM Images' ]

, -outputDir   => 'slideImages'
};

sub view2image($$$)
{   my ($export, $show, $slide, $view) = @_;

    print PPresenter::TRACE "Dumping image for $view.\n";

    my $image = $export->windowImage($show, $slide, $view);
    return unless defined $image;

    $export->polishImage($image);
    $image;
}

sub readImage($)
{   my ($export, $file) = @_;

    my $img   = Image::Magick->new;
    my $error = $img->Read($file);
    return $img unless $error;

    print "Magick error on reading image from $file: $error\n";
    undef;
}

sub polishImage($)
{   my ($export, $img) =@_;

    $img->Zoom(geometry => "$export->{-imageWidth}x10000")
        if defined $export->{-imageWidth} && $export->{-imageWidth} != 0;

    my $format = lc $export->{-imageFormat};

    $img->Set( magick    => $format
             , quality   => $export->{-imageQuality}
             , interlace => ($format eq 'png' ? 'Plane' : 'Line')
             );

    $export;
}

sub writeImage($$)
{   my ($export, $image, $file) = @_;

    $image->Set(filename => $file);
    my $error = $image->Write;
    warn "Couldn't write image: $error.\n" if $error;
    $export;
}

sub getDimensions($)
{   my ($export, $image) = @_;
    $image->Get('width', 'height');
}

#
# The user interface to this module.
#

sub popup($$)
{   my ($export, $show, $screen) = @_;
    return $export->{popup}
        if exists $export->{popup};

    $export->{popup} = my $popup = MainWindow->new(-screen => $screen
    , -title => 'Export images'
    );
    $popup->withdraw;

    my $vp = $export->tkViewportSettings($show, $popup);
    my $im = $export->tkImageSettings($show, $popup);

    my $options = $popup->Frame;
    $options->Label
    ( -text     => 'export'
    , -anchor   => 'e'
    )->grid($export->tkSlideSelector($popup), -sticky => 'ew');

    $options->Label
    ( -text     => 'output dir'
    , -anchor   => 'e'
    )->grid($options->Entry(-textvariable => \$export->{-outputDir})
           , -sticky => 'ew');

    my $commands = $popup->Frame;
    $commands->Button
    ( -text      => 'Export'
    , -relief    => 'ridge'
    , -command   => sub {$export->export($show, $popup)}
    )->grid($commands->Button
       ( -text      => 'Cancel'
       , -relief    => 'sunken'
       , -command   => sub {$popup->withdraw}
       )
    , -padx => 10, -pady => 10
    );

    $im      ->grid(-sticky => 'ew');
    $options ->grid(-sticky => 'ew');
    $vp      ->grid(-sticky => 'ew') if defined $vp;
    $commands->grid(-columnspan => 2, -sticky => 'ew');

    $popup->Popup(popover => 'cursor');
}

sub export($$)
{   my ($export, $show, $popup) = @_;

    $export->createDirectory($popup, $export->{-outputDir}) || return;
    $popup->withdraw;

    return if 'Cancel' eq $popup->Dialog
    (   -title    => 'Starting Export'
    ,   -text     => <<TEXT
Starting the export of you presentation as images.

Each of the slides will be shown, and then has its picture taken.

Do not touch your mouse while the processing is going on.
TEXT
    ,   -bitmap   => 'info'
    ,   -buttons  => [ 'OK', 'Cancel' ]
    )->Show;

    print PPresenter::TRACE "Exporting slides to images started.\n";

    $export->mapExportedPhases
    ( $show
    , sub { my ($export, $show, $slide, $viewports) = @_;
            $export->makeSlide($show, $slide, $viewports);
          }
    );

    $popup->Dialog
    (   -title    => 'Ready'
    ,   -text     => 'The images are ready.'
    ,   -bitmap   => 'info'
    ,   -buttons  => [ 'OK' ]
    )->Show;

    print PPresenter::TRACE "Exporting slides to images ready.\n";

    $export;
}

sub makeSlide($$$)
{   my ($export, $show, $slide, $viewports) = @_;

    $export->mapSlideViewports($show, $slide, $viewports
       , sub {shift->makeSlideView(@_)}
       );
}

sub makeSlideView($$$)
{   my ($export, $show, $slide, $view) = @_;

    my $image  = $export->view2image($show, $slide, $view);
    return unless $image;

    my $filename = $export->slide2filename($show,$slide,$view);
    $export->writeImage($image, $filename);
    $filename;
}

sub slide2filename($$$)
{   my ($export, $show, $slide, $view) = @_;

    sprintf "%s/%03d-%d-%s.%s"
    , $export->{-outputDir}, $slide->number, $slide->phase
    , $view->viewport, lc $export->{-imageFormat}; 
}

1;

