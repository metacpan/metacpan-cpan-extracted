############################################################
#
# OpenGL::Image::Common - Copyright 2007 Graphcomp - ALL RIGHTS RESERVED
# Author: Bob "grafman" Free - grafman@graphcomp.com
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
############################################################

package OpenGL::Image::Common;

require Exporter;

use Carp;

use vars qw($VERSION @ISA);
$VERSION = '1.01';

@ISA = qw(Exporter);



=head1 NAME

  OpenGL::Image::Common - copyright 2007 Graphcomp - ALL RIGHTS RESERVED
  Author: Bob "grafman" Free - grafman@graphcomp.com

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.


=head1 DESCRIPTION

  This module provides a base class for OpenGL imaging engines.
  Requires the OpenGL module.


=head1 SYNOPSIS

  ##########
  # Check for installed imaging engines

  use OpenGL::Image::Common;
  my $img = new OpenGL::Image::Common(%params);


  ##########
  # Must supply width and height, or source:

  # source - source image file path (some engines supports URLs).
  # width,height - width and height in pixels for cache allocation.


  ##########
  # Optional params:

  # engine - specifies imaging engine; defaults to 'Targa'.


  ##########
  # Methods defined in this Common module:

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

  # version - version of the engine
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
  # APIs defined in engine modules:

  # Get engine version
  my $ver = OpenGL::Image::ENGINE_MODULE::EngineVersion();

  # Get engine description
  my $desc = OpenGL::Image::ENGINE_MODULE::EngineDescription();


  ##########
  # Methods defined in engine modules:

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

  # Save the image to a PNG file (assuming the native engine supports PNGs).
  $img->Save('MyImage.png');

  # Get image blob.
  my $blob = $img->GetBlob();

=cut


# Base constructor
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my %params = @_;
  my $self = {params=>\%params};
  bless($self,$class);

  # Save CPU endian-ness as default
  $self->{params}->{endian} = unpack("h*", pack("s", 1)) =~ /01/ || 0;

  return $self;
}

# Return engine's native object
sub Native
{
  my($self) = @_;
  return $self->{native};
}

# Test for Power of 2
sub IsPowerOf2
{
  my($self,@values) = @_;

  if (!scalar(@values))
  {
    my $params = $self->{params};
    return 0 if (!$params->{width} || !$params->{height});
    @values = ($params->{width},$params->{height});
  }

  foreach my $value (@values)
  {
    return 0 if (!po2($value));
  }
  return 1;
}
sub po2
{
  my($value) = @_;

  while ($value)
  {
    return 1 if ($value == 1);
    return 0 if ($value & 1);
    $value >>= 1;
  }
  return 0;
}
sub GetPowerOf2
{
  my($self,@values) = @_;

  if (!scalar(@values))
  {
    my $params = $self->{params};
    return 0 if (!$params->{width} || !$params->{height});
    @values = ($params->{width},$params->{height});
  }
  my($value) = sort(@values);

  my $size = 0;
  while ($value)
  {
    $size++;
    $value >>= 1;
  }
  return $size ? 2**($size-1) : 0;
}

# Get parameter values
sub Get
{
  my($self,@params) = @_;
  return $self->{params} if (!scalar(@params));

  my @values = ();
  foreach my $param (@params)
  {
    push(@values,$self->{params}->{$param});
  }

  return @values;
}

# Get normalized pixels
sub GetPixel
{
  my($self,$x,$y,$count) = @_;

  my $w = $self->{params}->{width};
  my $c = $self->{params}->{components};
  my $s = $self->{params}->{size};
  my $n = (1 << ($s * 8)) - 1;

  my $pos = ($y * $w + $x) * $c;
  my $len = $c * ($count || 1);

  my @pad = ();
  push(@pad,0) if ($c < 2);
  push(@pad,0) if ($c < 3);
  push(@pad,1) if ($c < 4);

  my $i = 0;
  my @pixels = ();
  my @data = $self->{oga}->retrieve($pos,$len);
  foreach my $value (@data)
  {
    push(@pixels,$value/$n);

    if ($c < 4)
    {
      my $e = $i++ % $c;
      push(@pixels,@pad) if ($e == $c-1);
    }
  }

  return @pixels;
}

# Set normalized pixels
sub SetPixel
{
  my($self,$x,$y,@values) = @_;

  my $w = $self->{params}->{width};
  my $c = $self->{params}->{components};
  my $s = $self->{params}->{size};
  my $n = (1 << ($s * 8)) - 1;

  my $pos = ($y * $w + $x) * $c;

  my $i = 0;
  my @data = ();
  foreach my $value (@values)
  {
    if ($c < 4)
    {
      my $e = $i++ % $c;
      next if ($e >= $c-1);
    }
    push(@data,int(.5+$value*$n));
  }
  $self->{oga}->assign($pos,@data);
}


1;
__END__

