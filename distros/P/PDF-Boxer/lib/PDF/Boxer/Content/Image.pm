package PDF::Boxer::Content::Image;
{
  $PDF::Boxer::Content::Image::VERSION = '0.004';
}
use Moose;
# ABSTRACT: a box that displays an image

use namespace::autoclean;

extends 'PDF::Boxer::Content::Box';

has 'src' => ( isa => 'Str', is => 'ro' );
has 'scale' => ( isa => 'Num', is => 'ro' );
has 'format' => ( isa => 'Str', is => 'ro', lazy_build => 1 );

has 'image' => ( is => 'rw', lazy_build => 1 );
has 'image_width' => ( isa => 'Int', is => 'rw', lazy_build => 1 );
has 'image_height' => ( isa => 'Int', is => 'rw', lazy_build => 1 );

has 'align' => ( isa => 'Str', is => 'ro' );
has 'valign' => ( isa => 'Str', is => 'ro' );

sub _build_pressure_width{ 1 }
sub _build_pressure_height{ 0 }

sub _build_format{
  my ($self) = @_;
  return unless $self->src;
  my ($ext) = $self->src =~ /\.([^\.]+)$/;
  return $ext;
}

sub _build_image{
  my ($self) = @_;
  die $self->src.": $!" unless -f $self->src;
  my $pdf = $self->boxer->doc->pdf;
  my $method = 'image_'.$self->format;
  return $self->boxer->doc->pdf->$method($self->src);
}

sub _build_image_width{
  my ($self) = @_;
  my $width = $self->image->width;
  if (my $sc = $self->scale){
    $width = $width * $sc / 100;
  }
  return $width;
}

sub _build_image_height{
  my ($self) = @_;
  my $height = $self->image->height;
  if (my $sc = $self->scale){
    $height = $height * $sc / 100;
  }
  return $height;
}




sub get_default_size{
  my ($self) = @_;
  return ($self->image_width, $self->image_height);
}

around 'render' => sub{
  my ($orig, $self) = @_;

  my $img = $self->image;

  my $gfx = $self->boxer->doc->gfx;

  my $x = $self->content_left;
  my $y = $self->content_top-$self->height;

  my @args = $self->scale ? ($self->scale/100) : ($self->image->width, $self->image->height);

  foreach($self->valign || ()){
    /^top/ && do { $y = $self->content_top - $self->image_height };
    /^cen/ && do { 
      my $bc = $self->content_top - ($self->content_height / 2);
      my $ic = $self->image_height / 2;
      $y = $bc - $ic;
    };
  }

  foreach($self->align || ()){
    /^rig/ && do { $x = $self->content_right - $self->image_width };
    /^cen/ && do { 
      my $bc = $self->content_left + ($self->content_width / 2);
      my $ic = $self->image_width / 2;
      $x = $bc - $ic;      
    };
  }

  $gfx->image($img, $x, $y, @args);

  $self->$orig();

};

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

PDF::Boxer::Content::Image - a box that displays an image

=head1 VERSION

version 0.004

=head1 AUTHOR

Jason Galea <lecstor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jason Galea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

