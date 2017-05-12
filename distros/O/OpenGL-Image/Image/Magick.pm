############################################################
#
# OpenGL::Image::Magick - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Image::Magick;

require Exporter;

use Carp;

use vars qw($VERSION $DESCRIPTION @ISA);
$VERSION = '1.02';

$DESCRIPTION = qq
{Supports optimized internal interfaces to the ImageMagick library.};

use OpenGL::Image::Common;
@ISA = qw(Exporter OpenGL::Image::Common);

use OpenGL(':constants');



=head1 NAME

  OpenGL::Image::Magick - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This is a driver module for use with the OpenGL module.
  While it may be called directly, it will more often be called
  by the OpenGL::Image abstraction module.

  Note: OpenGL::Image defaults to this module.

  This is a subclass of the OpenGL::Image::Common module.

  Requires the Image::Magick module; 6.3.5 or newer is recommended.


=head1 SYNOPSIS

  ##########
  # Check for installed imaging engines

  use OpenGL::Image;
  my $img = new OpenGL::Image(engine=>'Magick',source=>'MyImage.png');


  ##########
  # Methods defined in the OpenGL::Image::Common module:

  # Get native engine object
  # Note: must not change image dimensions
  my $obj = $img->Native;
  $obj->Quantize() if ($obj);

  # Alternately (Assuming the native engine supports Blur):
  $img->Native->Blur();

  # Test if image width is a power of 2
  if ($img->IsPowerOf2());

  # Test if all listed values are a power of 2
  if ($img->IsPowerOf2(@list));

  # Get largest power of 2 size within dimensions of image
  my $size = $img->GetPowerOf2();

  # Get all parameters as a hashref
  my $params = $img->Get();

  # Get one or more parameter values
  my @values = $img->Get(@params);

  # Get/Set Pixel values (normalized to 1.0)
  my($r,$g,$b,$a) = $img->GetPixel($x,$y);

  # Sync cache after done modifying pixels
  $img->SetPixel($x,$y,$r,$g,$b,$a);
  $frame->Sync();


  ##########
  # Supported parameters:

  # source - source image, if defined
  # width - width of image in pixels
  # height - height of image in pixels
  # pixels - number of pixels
  # components - number of pixel components
  # size - bytes per component
  # length - cache size in bytes
  # endian - 1 if big endian; otherwise 0
  # alpha - 1 if has alpha channel, -1 if has inverted alpha channel; 0 if none
  # flipped - 1 bit set if cache scanlines are top to bottom; others reserved
  # gl_internalformat - internal GL pixel format. eg: GL_RGBA8, GL_RGBA16
  # gl_format - GL pixel format. eg: GL_RGBA, GL_BGRA
  # gl_type - GL data type.  eg: GL_UNSIGNED_BYTE, GL_UNSIGNED_SHORT


  ##########
  # APIs defined in this module:

  # Get engine version
  my $ver = OpenGL::Image::THIS_MODULE::EngineVersion();

  # Get engine description
  my $desc = OpenGL::Image::ENGINE_MODULE::EngineDescription();


  ##########
  # Methods defined in this module:

  # Sync the image cache after modifying pixels.
  # Used by some engines for paged caches; otherwise a NOP.
  $img->Sync();

  # Return the image's cache as an OpenGL::Array object.
  # Note: OGA may change after a cache update
  my $oga = $img->GetArray();

  # Return a C pointer to the image's cache.
  # For use with OpenGL's "_c" APIs.
  # Note: pointer may change after a cache update
  $img->Ptr();

  # Save file - automatically does a Sync before write
  $img->Save('MyImage.png');

  # Get image blob.
  my $blob = $img->GetBlob();

=cut

eval 'use Image::Magick';


# Get engine version
sub EngineVersion
{
  return $Image::Magick::VERSION;
}

# Get engine description
sub EngineDescription
{
  return $DESCRIPTION;
}

# Base constructor
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = new OpenGL::Image::Common(@_);
  return undef if (!$self);

  $self->{params}->{engine} = 'Magick';
  $self->{params}->{version} = EngineVersion();

  $self->{params}->{components} = 4;
  $self->{params}->{alpha} = 0;
  $self->{params}->{flipped} = 1;

  # Use source image if supplied
  my $img;
  if ($self->{params}->{source})
  {
    $img = new Image::Magick();
    return undef if (!$img);

    my $stat = $img->Read($self->{params}->{source});
    return undef if ($stat);

    ($self->{params}->{width},$self->{params}->{height}) =
      $img->Get('Width','Height');
    return undef if (!$self->{params}->{width} || !$self->{params}->{height});

    $self->{native} = $img;
  }
  # Otherwise create uninitialized image
  else
  {
    my $w = $self->{params}->{width};
    my $h = $self->{params}->{height};
    my $blob = $self->{params}->{blob};

    if ($w && $h)
    {
      my $dim = $w.'x'.$h;
      $self->{native} = new Image::Magick(size=>$dim, magick=>'RGBA', depth=>8);
    }
    elsif ($blob)
    {
      $self->{native} = new Image::Magick();
    }
    return undef if (!$self->{native});
    $img = $self->{native};

    # Populate with blob
    if ($blob)
    {
      my $stat = $img->BlobToImage($blob);
      return undef if ($stat);

      if (!$w || !$h)
      {
        ($self->{params}->{width},$self->{params}->{height}) =
          $img->Get('Width','Height');
      }
    }
    # Otherwise fill with 'none'
    else
    {
      my $stat = $img->Read('xc:none');
      return undef if ($stat);
      $img->Set(type=>'truecolormatte');
    }
  }

  my $alpha = $img->Get('matte');
  $img->Set('matte'=>'True') if (!$alpha);

  # Good to go
  bless($self,$class);

  # Init params
  return undef if (!$self->init());
  $self->SyncOGA();

  return $self;
}

# Initialize object
sub init
{
  my($self) = @_;

  my $w = $self->{params}->{width};
  my $h = $self->{params}->{height};
  $self->{params}->{pixels} = $w * $h; 

  my $elements = $self->{params}->{pixels} * $self->{params}->{components};

  my $img = $self->{native};

  # Use C pointer to image cache, if supported
  if ($self->{params}->{version} ge '6.3.5')
  {
    my $q = $img->Get('quantum');

    if ($q == 8)
    {
      $self->{params}->{gl_internalformat} = GL_RGBA8;
      $self->{params}->{gl_type} = GL_UNSIGNED_BYTE;
      $self->{params}->{size} = 1;
    }
    elsif ($q == 16)
    {
      $self->{params}->{gl_internalformat} = GL_RGBA16;
      $self->{params}->{gl_type} = GL_UNSIGNED_SHORT;
      $self->{params}->{size} = 2;
    }
    else
    {
      print "Unsupported pixel quantum\n";
    }

    if ($self->{params}->{gl_type})
    {
      $self->{params}->{gl_format} = 
        $self->{params}->{endian} ? GL_RGBA : GL_BGRA;

      $self->{params}->{length} =  $self->{params}->{size} * $elements;

      $self->{oga} = OpenGL::Array->new_pointer($self->{params}->{gl_type},
        $img->GetImagePixels(rows=>$h),$elements);

      $self->{params}->{alpha} = -1;

      return $self->{oga};
    }
  }

  # Fall back to using standard PerlMagick interface
  $self->{blobs} = 1;
  $self->{params}->{gl_internalformat} = GL_RGBA8;
  $self->{params}->{gl_type} = GL_UNSIGNED_BYTE;
  $self->{params}->{size} = 1;
  $self->{params}->{gl_format} = GL_RGBA;
  $self->{params}->{alpha} = 1;

  $self->{params}->{length} =
    $self->{params}->{pixels} * $self->{params}->{components} *
    $self->{params}->{size};

  $img->Set(magick=>'RGBA',depth=>8);
  $self->{oga} = OpenGL::Array->new_scalar($self->{params}->{gl_type},
    $img->ImageToBlob(),$elements);

  return $self->{oga};
}

# Sync from GPU framebuffer (OGA/blob) to IM
# Call before using native calls
sub Sync
{
  my($self) = @_;

  my $img = $self->{native};
  if ($self->{blobs})
  {
    $img->BlobToImage($self->{oga}->retrieve_data());
  }
  else
  {
    $img->SyncImagePixels();
  }

  $img->Negate(channel=>'Alpha') if ($self->{params}->{alpha} < 0);
  $img->Flip();
}

# Sync from IM to GPU framebuffer (OGA/blob)
# Call after using native calls
sub SyncOGA
{
  my($self) = @_;

  my $img = $self->{native};

  $img->Flip();
  $img->Negate(channel=>'Alpha') if ($self->{params}->{alpha} < 0);

  my($w,$h) = $img->Get('width','height');
  my $pixels = $w * $h;
  my $elements = $pixels * $self->{params}->{components};

  if ($self->{blobs})
  {
    $img->Set(magick=>'RGBA',depth=>8);

    $self->{oga} = OpenGL::Array->new_scalar($self->{params}->{gl_type},
      $img->ImageToBlob(),$elements);
  }

  if ($w == $self->{params}->{width} && $h == $self->{params}->{height})
  {
    return if ($self->{blobs});
    $self->{oga}->update_pointer($img->GetImagePixels(rows=>$h));
  }

  $self->{params}->{width} = $w;
  $self->{params}->{height} = $h;
  $self->{params}->{pixels} = $pixels; 
  $self->{params}->{length} = $elements * $self->{params}->{size};

  return if ($self->{blobs});

  $self->{oga} = OpenGL::Array->new_pointer($self->{params}->{gl_type},
    $img->GetImagePixels(rows=>$h),$elements);
}

# Get OpenGL::Array object
sub GetArray
{
  my($self) = @_;
  return $self->{oga};
}

# Get C pointer to image cache
sub Ptr
{
  my($self) = @_;
  return undef if (!$self->{oga});
  return $self->{oga}->ptr();
}

# Save image
sub Save
{
  my($self,$file,%user_params) = @_;
  my $img = $self->{native};

  $self->Sync();

  my $blob;
  if ($file)
  {
    if ($self->{blobs} && $img->[1])
    {
      $img->[1]->Write(filename=>$file,%user_params);
    }
    else
    {
      $img->[0]->Write(filename=>$file,%user_params);
    }
  }
  else
  {
    %user_params = (magick=>'RGBA',depth=>8) if (!scalar(%user_params));
    delete($user_params{filename});

    my $clone = $img->Clone();
    $clone->Set(%user_params);
    ($blob) = $clone->ImageToBlob();
  }

  $self->SyncOGA();

  return $blob;
}

# Get image blob
sub GetBlob
{
  my($self,%params) = @_;
  return $self->Save(undef,%params);
}

1;
__END__

