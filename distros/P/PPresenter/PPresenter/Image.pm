# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Image;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';
use File::Basename;

use constant ObjDefaults =>
{ -name        => ''    # defaults to filename later
, -aliases     => undef
, -file        => undef
, -sizeBase    => undef
, -resize      => undef
, -enlarge     => undef

, show         => undef

, ino          => undef # to determine equivalent images with
, dev          => undef #    used under different name.
, source       => undef
};

sub InitObject()
{   my $img = shift;
    $img->SUPER::InitObject;

    # Find a name for the image.

    (my $basename = $img->{-file}) =~ s|^.*/([^\.]*)|$1|g;

    if($img->{-name} eq '') {$img->{-name} = $basename}
    else                    {push @{$img->{-aliases}}, $basename}

    push @{$img->{aliases}}, $img->{-file};

    # Find-out for which screen-size this image was created.

    my $show = $img->{show};
    $img->{-sizeBase} = $show->imageSizeBase
        unless defined $img->{-sizeBase};

    $img->{-resize} = ($show->resizeImages && defined $img->{-sizeBase})
        unless defined $img->{-resize};

    $img->{-enlarge} = ($show->enlargeImages && defined $img->{-sizeBase})
        unless defined $img->{-enlarge};

    $img;
}

sub sameSource($)
{   my ($img, $options) = @_;

    if($options->{ino}==0)
    {   # Non-UNIX, so have to fake our way out.
        return -s $options->{source} == -s $img->{source}
               && basename $options->{source} eq basename $img->{source}
    }
    else
    {   # UNIX: same file is safely detectable.
        return $options->{ino}==$img->{ino}
               && $options->{dev}==$img->{dev}
    }
}

sub scaling($)
{   my ($img,$viewport) = @_;

    return 1.0 unless $img->{-resize};
    my $scaling = $viewport->geometryScaling($img->{-sizeBase});
    ($scaling < 1.0 || $img->{-enlarge}) ? $scaling : 1.0;
}

1;
