# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Images;

use strict;
use PPresenter::Object;
use PPresenter::Image;

use base 'PPresenter::Object';

use constant ObjDefaults =>
{ -name      => 'image registry'
, -imageDirs => undef
, show       => undef
, tmpdir     => undef
, images     => []
};

sub InitObject()
{   my $self = shift;
    $self->SUPER::InitObject;

    $self->addImageDir('.', 'PPresenter/images');

    my $tmp = $self->{tmpdir} || undef;

    unless($tmp)
    {   $tmp = defined $ENV{TMPDIR} ? "$ENV{TMPDIR}/gpp.$$"
             : -d '/tmp' ? "/tmp/gpp.$$"
             : "scaled.$$";
        $self->{tmpdir} = $tmp;
    }
    
    ! -d $tmp && mkdir $tmp, 0700
        or die "Couldn't create $tmp for scaled images.\n";
    
    eval "END {\$self->cleanup_imagedir('$tmp')}";
        
    $self;
}

sub cleanup_imagedir($)
{   my ($self, $dir) = @_;

    print PPresenter::TRACE "Removing scaled images in $dir.\n";

    $self->{show}->remove_dir($dir);
}

sub findImageFile($)
{   my ($self, $filename) = @_;

    foreach (@{$self->{imageDirs}})
    {   return "$_/$filename" if -f "$_/$filename";
    }

    return undef;
}

sub addImageDir(@)
{   my $self = shift;

    foreach my $dir (@_)
    {   if($dir =~ m[^/])
        {   unshift @{$self->{imageDirs}}, $dir;
            next;
        }

        my @add = map { -d "$_/$dir" ? "$_/$dir" : () } @INC;
        warn "Image directory `$dir' not found.\n" if $^W && @add==0;
        push @{$self->{imageDirs}}, @add;
    }

    $self;
}

sub image(@)             # user calls $show->image(...)
{   my $self = shift;

    return unless @_;
    my $obj = $_[0];

    return $self->createImage(@_) unless ref $obj;
    return $obj                   if $obj->isa('PPresenter::Image');

    push @_, show => $self->{show};

    if($obj->isa('Tk::Photo'))
    {   require PPresenter::Image::tkPhoto;
        my $img = PPresenter::Image::tkPhoto->convert(@_);

        warn "Two images named $img.\n"
           if $^W && $self->findImage($img);

        push @{$self->{images}}, $img;
        return $img;
    }

    if($obj->isa('Image::Magick'))
    {   require PPresenter::Image::Magick;
        my @imgs = PPresenter::Image::Magick->convert(@_);
        foreach (@imgs)
        {   warn "Image $_ redefined.  Use -name to diverse them.\n"
                if $self->findImage($_);
        }
        push @{$self->{images}}, @imgs;
        return @imgs;
    }

    warn "What do you try to feed me? A ",ref $obj," is not an image, is it?\n";
    return;
}

sub createImage(@)
{   my $self = shift;
    my $show = $self->{show};

    my %options = ( @_
    , show     => $show
    );

    my $source = $options{-file};
    unless(defined $source)
    {   warn "No image file or image name specified.\n";
        return;
    }

    my $img = $self->findImage($source);
    return $img if $img;

    $source = $self->findImageFile($source)
        unless $source =~ m[^/];

    unless(defined $source)
    {   warn "Cannot find image file $options{-file}.\n";
        return;
    }

    unless(-r $source)
    {   warn "Cannot read image file $source.\n";
        return;
    }

    @options{'dev', 'ino'} = (stat $source)[0,1];
    $options{source}       = $source;

    foreach (@{$self->{images}})
    {   return $_ if $_->sameSource(\%options);
    }

    print PPresenter::TRACE "Defining new image $source.\n";

    if($show->hasImageMagick)
    {   require PPresenter::Image::Magick;
        $img = PPresenter::Image::Magick->new(%options);
    }
    else
    {   require PPresenter::Image::tkPhoto;
        $img = PPresenter::Image::tkPhoto->new(%options);
    }

    return unless $img;

    push @{$self->{images}}, $img;
    $img;
}

sub findImage($) {PPresenter::Image->fromList(shift->{images}, shift)}

1;
