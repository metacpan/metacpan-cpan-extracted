package OpenFrame::Segment::Apache2::NoImages;

use strict;
use warnings;

use File::MMagic;
use File::Spec::Functions qw(splitpath catfile);
use Pipeline::Segment;
use OpenFrame::Response;
use base qw(Pipeline::Segment);

our $VERSION = '1.00';

sub directory {
  my($self, $dir) = @_;

  if (defined $dir) {
    $self->{directory} = $dir;
    return $self;
  } else {
    return $self->{directory};
  }
}

sub dispatch {
  my($self, $pipe) = @_;

  # get the path from the request, via the store.
  my $ofr  = $pipe->store->get('OpenFrame::Request');
  my $path = $ofr->uri->path();
  # add the images directory
  my ($volume, $dirs, $file) = splitpath( $path );
  my $realfile = catfile( $self->directory, $dirs, $file );

  $self->emit("trying to access $realfile");

  return unless -f $realfile;
  return unless -r _;

  my $mm = File::MMagic->new();
  my $type = $mm->checktype_filename($realfile);
  return unless $type =~ /^image/ || $file =~ /swf$/;

  $self->emit("declining image");

  my $response = OpenFrame::Response->new();
  $response->code(ofDECLINE());
  $response->message("let apache take care of it");
  $response->mimetype($type);
  return $response;
}

1;

__END__

=head1 NAME

OpenFrame::Segment::Apache2::NoImages - a pipeline segment to manage images

=head1 SYNOPSIS

  use OpenFrame::Segment::Apache2::NoImages;;
  my $images_engine = OpenFrame::Segment::Apache2::NoImages->new();
  $images_engine->directory("./images");

=head1 DESCRIPTION

The C<OpenFrame::Segment::Apache2::NoImages> class is a pipeline
segment and inherits its interface from there. It returns
OpenFrame::Responses declining images (letting Apache2 serve them
instead).

=head1 AUTHOR

Leon Brocard <leon@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd. All Rights Reserved

This program is released under the same license as Perl itself.


