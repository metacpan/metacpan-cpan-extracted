############################################################
#
# OpenGL::Image::Targa - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Image::Targa;

require Exporter;

use Carp;

use vars qw($VERSION $DESCRIPTION @ISA);
$VERSION = '1.01';

$DESCRIPTION = qq
{Supports uncompressed RGBA files; default engine driver.
May be used as a prototype for other imaging drivers};

use OpenGL::Image::Common;
@ISA = qw(Exporter OpenGL::Image::Common);

use OpenGL(':constants');



=head1 NAME

  OpenGL::Image::Targa - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This is a driver module for use with the OpenGL module.
  While it may be called directly, it will more often be called
  by the OpenGL::Image abstraction module.

  This is a subclass of the OpenGL::Image::Common module.


=head1 SYNOPSIS

  ##########
  # Check for installed imaging engines

  use OpenGL::Image;
  my $img = new OpenGL::Image(engine=>'Targa',source=>'MyImage.tga');


  ##########
  # Methods defined in the OpenGL::Image::Common module:

  # Get native engine object
  # Note: No native Targa object

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
  # Note: Sync is a NOP for this module
  $img->Sync();

  # Return the image's cache as an OpenGL::Array object.
  # Note: OGA may change after a cache update
  my $oga = $img->GetArray();

  # Return a C pointer to the image's cache.
  # For use with OpenGL's "_c" APIs.
  $img->Ptr();

  # Save file
  $img->Save('MyImage.tga');

  # Get image blob.
  my $blob = $img->GetBlob();

=cut


# Get engine version
sub EngineVersion
{
  return $VERSION;
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
  bless($self,$class);

  $self->{native} = undef;

  my $params = $self->{params};
  $params->{engine} = 'Targa';
  $params->{version} = $VERSION;

  $params->{gl_internalformat} = GL_RGBA8;
  $params->{gl_format} = $params->{endian} ? GL_RGBA : GL_BGRA;
  $params->{gl_type} = GL_UNSIGNED_BYTE;
  $params->{alpha} = 1;
  $params->{components} = 4;
  $params->{flipped} = 0;
  $params->{size} = 1;

  my $blob = '';
  my $file = $params->{source};
  if ($file)
  {
    return undef if (!-e $file);
    $blob = $self->read_file($file);
  }
  else
  {
    $blob = $self->init();
  }
  return undef if (!$blob);

  $self->{oga} = OpenGL::Array->new_scalar(GL_UNSIGNED_BYTE,$blob,length($blob));
  return undef if (!$self->{oga});

  return $self;
}

# read file
sub read_file
{
  my($self,$file) = @_;
  return undef if (!open(FILE,$file));
  binmode(FILE);

  my $buf;
  my $len = read(FILE,$buf,18);
  if ($len != 18)
  {
    close(FILE);
    return undef;
  }

  # Parse header
  my
  (
    $id_len,    # byte
    $cmap_type, # byte
    $image_type,# byte
    $cmap_org,  # short
    $cmap_len,  # short
    $cmap_size, # byte
    $x_org,     # short
    $y_org,     # short
    $w,         # short
    $h,         # short
    $pix_size,  # byte
    $pix_attrs  # byte
  ) = unpack('C C C S S C S S S S C C',$buf);

  # Check for cmap
  if ($cmap_type)
  {
    close(FILE);
    return undef;
  }

  # Only supporting 24 bit RGB or 32 bit RGBA at this time
  if (!($pix_size == 32 && $pix_attrs == 8) &&
    !($pix_size == 24 || $pix_attrs == 0))
  {
    close(FILE);
    return undef;
  }

  # read file identifier, if any
  if ($id_len)
  {
    $len = read(FILE,$buf,$id_len);
    return close(FILE) if ($len != $id_len);
  }

  # Save file attrs
  my $params = $self->{params};
  $params->{width} = $w;
  $params->{height} = $h;
  $params->{pixels} = $w * $h;
  my $data_len = $w * $h * 4;
  $params->{length} = $data_len;
  $buf = '';

  # Handle runlength-encoded RGB
  if ($image_type == 10)
  {
    my($data,$count,$rle);
    my $size = $pix_size / 8;
    $len = 0;

    while (($len < $data_len) && (read(FILE,$data,1) == 1))
    {
      $count = ord($data);
      $rle = $count & 128;

      if ($rle)
      {
        $count &= 127;
        $count++;
        last if (read(FILE,$data,$size) != $size);
        $data .= chr(0xFF) if ($size != 4);
        $buf .= $data x $count;
        $len += $count * 4;
      }
      # Raw 32 bit pixels
      elsif ($pix_size == 32)
      {
        $count++;
        $count *= 4;
        last if (read(FILE,$data,$count) != $count);
        $buf .= $data;
        $len += $count;
      }
      # Raw 24 bit pixels
      else
      {
        $count++;
        $len += $count * 4;
        for (my $i=0; $i<$count; $i++)
        {
          last if (3 != read(FILE,$data,3));
          $buf .= $data.chr(0xFF);
        }
      }
    }
  }
  # Unsupported image type
  elsif ($image_type != 2)
  {
    close(FILE);
    return undef;
  }
  # Read 32 bit images
  elsif ($pix_size == 32)
  {
    $len = read(FILE,$buf,$data_len);
  }
  # Read 24 bit images; add alpha channel
  else
  {
    my $pixel;
    for (my $i=0; $i<$w*$h; $i++)
    {
      last if (3 != read(FILE,$pixel,3));
      $buf .= $pixel.chr(0xFF);
    }
    $len = length($buf);
  }
  close(FILE);

  # Pad out buffer if it's short
  if ($len < $data_len)
  {
    my $pixel = chr(0) x 4;
    $buf .= $pixel x ($data_len - $len);
  }
  return $buf;
}

# Initialize empty blob
sub init
{
  my($self) = @_;
  my $params = $self->{params};

  my $w = $params->{width};
  my $h = $params->{height};
  $params->{pixels} = $w * $h; 

  my $buf;
  my $pix = pack('C C C C', 0, 0, 0, 255);
  for (my $i=0; $i<$params->{pixels}; $i++)
  {
    $buf .= $pix;
  }
  return $buf;
}

# Sync image cache
sub Sync
{
  return undef;
}

# Sync oga
sub SyncOGA
{
  return undef;
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
  my($self,$file) = @_;
  return undef if (!$file);

  my $blob = $self->GetBlob();
  return undef if (!$blob);

  return undef if (!open(FILE,">$file"));
  binmode(FILE);

  my $params = $self->{params};
  my $w = $params->{width};
  my $h = $params->{height};

  my $hdr = pack('C C C S S C S S S S C C',
    0, 0, 2, 0, 0, 0, 0, 0, $w, $h, 32, 8);

  print FILE $hdr.$blob;
  close(FILE);

  return $blob;
}

# Get image blob
sub GetBlob
{
  my($self) = @_;
  return $self->{oga}->retrieve_data();
}

1;
__END__

