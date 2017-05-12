# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Image::tkPhoto;

use strict;
use Tk::Photo;
use PPresenter::Image;
use base qw(PPresenter::Image Tk::Photo);

my $unique;

sub convert($@)
{   my ($class, $show) = shift;

    my (@photos, @images);
    push @photos, shift
       while @_ && ref $_[0] && $_[0]->isa('Tk::Photo');

    unshift @_, -file => 'converted', -name => 'tk'.$unique++;

    foreach (@photos)
    {   my $img = $class->new( @_ );
        my $viewport = $_->MainWindow;

        $img->{"photo_$viewport"} = $_;
        $img->{source} = $_;

        push @images, $img;
        print PPresenter::TRACE "Added image $img.\n";
    }

    @images;
}

sub prepare($$)
{   my ($img, $viewport, $canvas) = @_;

    my $vplabel = "photo_$viewport";
    return $img if exists $img->{$vplabel};

    my $photo = ref $img->{source}
              ? $canvas->Photo->copy($img->{source})
              : $canvas->Photo(-file => $img->{source});

    unless(defined $photo)
    {   warn "Cannot read photo from $img->{source}.\n";
        return;
    }
  
    $img->{$vplabel} = $img->scale_photo($photo, $viewport, $canvas);
    $img;
}

sub scale_photo($$$)
{   my ($img, $photo, $viewport, $canvas) = @_;

    my $scaling = $img->scaling($viewport);

    if($scaling<0.67)
    {   $scaling = int(1/$scaling +0.5);
        print PPresenter::TRACE
           "Subsampling Tk::Photo $img with $scaling for viewport $viewport.\n";

        my $shrunk = $canvas->Photo( -width  => int($photo->width/$scaling)
                                   , -height => int($photo->height/$scaling));
        $shrunk->copy($photo, -subsample => $scaling, $scaling);
        return $shrunk;
    }

    if($scaling>1.5)
    {   $scaling = int($scaling+0.5);
        warn "Poor image quality because $img is enlarged (by $scaling).\n"
            if $^W;

        print PPresenter::TRACE
             "Zoom Tk::Photo $img $scaling times for viewport $viewport.\n";

        my $zoomed = $canvas->Photo( -width  => int($photo->width*$scaling)
                                   , -height => int($photo->height*$scaling));
        $zoomed->copy($photo, -zoom => $scaling, $scaling);
        return $zoomed;
    }

    return $photo;
}

sub show($$$)
{   my ($img, $viewport, $canvas, $x, $y) = splice @_, 0, 5;
    my $vplabel = "photo_$viewport";

    $img->{$vplabel} = $img->prepare($viewport, $canvas)
        unless exists $img->{$vplabel};

    $canvas->createImage
    ( $x, $y
    , -image => $img->{$vplabel}
    , @_
    );

    $img;
}

sub dimensions($)
{   my ($img, $viewport) = @_;
    my $photo = $img->{"photo_$viewport"};
    ($photo->width, $photo->height);
}

1;
