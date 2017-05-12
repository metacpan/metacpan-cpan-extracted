# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Export::Handouts::IM_PostScript;

use strict;
use PPresenter::Export::Images::ImageMagick;
use PPresenter::Export::Handouts::PostScript;

use base qw(PPresenter::Export::Images::ImageMagick
            PPresenter::Export::Handouts::PostScript);

use Tk;
use Tk::Dialog;

use constant ObjDefaults =>
{ -name        => 'PostScript handouts with ImageMagick'
, -aliases     => [ 'IM Postscript', 'imps', 'im ps' ]

, -outputDir   => ($ENV{TMPDIR} || '/tmp')
, -imageFormat => 'eps'
, -outputFile  => 'show.ps'
, -orientation => 'Best fit'
, -paperUse    => '1'
};

my @paper_placers =
( [ '1'    , \&make1slide_pp,  'export_ps1.xbm'    ]
, [ '12'   , \&make2slides_pp, 'export_ps12.xbm'   ]
, [ '12 34', \&make4slides_pp, 'export_ps1234.xbm' ]
, [ '13 24', undef, 'export_ps1324.xbm' ]
);

sub exportPostscript($$)
{   my ($export, $show, $popup) = @_;

    $popup->destroy;

    print PPresenter::TRACE
        "Exporting slides to PostScript via ImageMagick started.\n";

    my @outfiles = $export->mapExportedPhases
      ( $show
      , sub { my ($export, $show, $slide, $viewports) = @_;
              $export->makeSlide($show, $slide, $viewports);
            }
      );

    my $pages = $export->paperPlacer->($export, \@outfiles);
    $export->setColors($pages, $export->{-colorMode});
    $export->writePages($pages
      , $export->{-outputFile}
      , $export->{-density}
      );

    print PPresenter::TRACE "Exporting slides to PostScript ready.\n";

    $export;
}

sub setColors($$)
{   my ($export, $pages, $mode) = @_;
    return $pages->Quantize(colorspace => 'Gray') if $mode eq 'gray';
    return $pages->Quantize(colors     => 2)      if $mode eq 'mono';
}

sub writePages($$$)
{   my ($export, $pages, $file, $density) = @_;

    $pages->Set(density => $density);
    my $error = $pages->Write($file);
    return unless $error;

    $export->{popup}->Dialog
    ( -text    => "Cannot write result to $file:\n$error"
    , -bitmap  => 'error'
    , -title   => 'Write error'
    , -buttons => [ 'Bummer!' ]
    )->Show;
}

sub fitToPaper($$$)
{   my ($export, $img, $pwidth, $pheight) = @_;
    my ($width, $height) = $img->Get('width', 'height');
    my $orientation = $export->{-orientation};

    $orientation = $export->bestOrientation($pwidth, $pheight, $width, $height)
        if $orientation eq 'Best fit';

    $img->Rotate(degrees => -90.0) if $orientation eq 'Landscape';
    $img->Set(quality => 100);
    $img->Zoom(geometry => "${pwidth}x${pheight}", blur => 0.5);
}

sub bestOrientation($$$$)
{   my ($export, $pw, $ph, $iw, $ih) = @_;

    $export->zoomToFit($pw,$ph, $iw,$ih) < $export->zoomToFit($pw,$ph, $ih,$iw)
    ? 'Landscape' : 'Portrait';
}

sub zoomToFit($$$$)
{   my ($export, $pw, $ph, $iw, $ih) = @_;
    my ($scale_x, $scale_y) = ($pw/$iw, $ph/$ih);
    $scale_x < $scale_y ? $scale_x : $scale_y;
}

sub read_image($$$$)
{   my ($export, $list, $file, $width, $height) = @_;
    return unless defined $file;

    my $error = $list->Read($file);
    die "Cannot read image from file $file: $error.\n" if $error;
    unlink $file;

    $export->fitToPaper($list->[-1], $width, $height);
}

sub make1slide_pp($$)
{   my ($export, $files) = @_;
    my ($width, $height) = $export->paperSizePixels;

    my $all_images = Image::Magick->new;

    foreach (@$files)
    {   $export->read_image($all_images, $_, $width, $height);
        $all_images->Set(page => "${width}x${height}");
    }

    $all_images;
}

sub make2slides_pp($$)
{   my ($export, $files) = @_;
    my ($width, $height) = $export->paperSizePixels;

    my $all_images = Image::Magick->new;

    while(@$files)
    {   my $part  = Image::Magick->new;
        $export->read_image($part, shift @$files, $width, $height/2);
        $export->read_image($part, shift @$files, $width, $height/2);
        push @$all_images, (@$part > 1 ? $part->Append : pop @$part);
    }

    $all_images;
}

sub make4slides_pp($$)
{   my ($export, $files) = @_;
    my ($width, $height) = $export->paperSizePixels;
    $width /= 2; $height /= 2;

    my $all_images = Image::Magick->new;

    while(@$files)
    {   my $page = Image::Magick->new;
        my $part1 = Image::Magick->new;
        $export->read_image($part1, shift @$files, $width, $height);
        $export->read_image($part1, shift @$files, $width, $height);
        push @$page, $part1->Append(-stack => 0);
        my $part2 = Image::Magick->new;
        $export->read_image($part2, shift @$files, $width, $height);
        $export->read_image($part2, shift @$files, $width, $height);
        push @$page, $part2->Append(-stack => 0);
        push @$all_images, $page->Append(-stack => 1);
    }

    $all_images;
}

#
# The user interface to this module.
#

sub popup($$)
{   my ($export, $show, $screen) = @_;

    my $popup = MainWindow->new(-screen => $screen
    , -title => 'Export slides with Postscript via ImageMagick'
    );
    $popup->withdraw;

    my $vp = $export->tkViewportSettings($show, $popup);
    my $ps = $export->tkPostscript($show, $popup);

    my $options = $popup->Frame;
    $options->Label
    ( -text     => 'export'
    , -anchor   => 'e'
    )->grid($export->tkSlideSelector($popup), -sticky => 'ew');

    $options->Label
    ( -text     => 'output file'
    , -anchor   => 'e'
    )->grid($options->Entry(-textvariable => \$export->{-outputFile})
           , -sticky => 'ew');

    my $commands = $popup->Frame;
    $commands->Button
    ( -text      => 'Export'
    , -relief    => 'ridge'
    , -command   => sub {$export->exportPostscript($show, $popup)}
    )->grid($commands->Button
       ( -text      => 'Cancel'
       , -relief    => 'sunken'
       , -command   => sub {$popup->withdraw}
       )
    , -padx => 10, -pady => 10
    );

    if(defined $vp)
    {   $vp->grid($ps, -sticky => 'ewns');
        $options->grid('^', -sticky => 'ew');
    }
    else {$options->grid($ps, -sticky => 'ew')}
    $commands->grid(-columnspan => 2, -sticky => 'ew');

    if(grep {$_->device ne 'printer'} $show->viewports)
    {   my $hint = $popup->LabFrame
        ( -label     => 'Hint'
        , -labelside => 'acrosstop'
        )->grid(-columnspan => 2, -sticky => 'ew');
        $hint->Label(-text => <<HINT
Black on white is usually nicer, so you may consider
the use `-device=>printer' for all viewports.
HINT
        )->grid(-sticky=>'nwsw');
    }

    $popup->Popup(popover => 'cursor');
}

sub tkPostscript($$)
{   my ($export, $show, $popup) = @_;
    my $ps = $export->SUPER::tkPostscript($show, $popup);

    my $options = $ps->Frame;
    foreach (@paper_placers)
    {   my ($label, $function, $bitmap) = @$_;
        $options->Checkbutton
        ( -bitmap      => '@'. $show->findImageFile($bitmap)
        , -onvalue     => $label
        , -variable    => \$export->{-paperUse}
        , -indicatoron => 0
        )->pack(-side => 'left');
    }

    $ps->Label
    ( -text     => 'Packing'
    , -anchor   => 'w'
    )->grid($options, '-', -sticky => 'ew');

    $ps;
}

sub paperPlacer()
{   my $export = shift;
    my $name   = $export->{-paperUse};

    return $name if ref $name eq 'CODE';

    foreach (@paper_placers)
    {   my ($label, $function, $bitmap) = @$_;
        return $function if $label eq $name;
    }

    die "Unknown map function $name.\n";
}

1;

