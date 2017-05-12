package OpenFrame::AppKit::Segment::Images;

use strict;
use warnings::register;

use IO::File;
use File::MMagic;
use File::Spec;
use Pipeline::Segment;
use OpenFrame::Response;

our $VERSION=3.03;
use base qw ( Pipeline::Segment );

sub directory {
  my $self = shift;
  my $dir  = shift;
  if (defined($dir)) {
    $self->{directory} = $dir;
    return $self;
  } else {
    return $self->{directory};
  }
}

sub dispatch {
  my $self = shift;
  my $pipe = shift;

  # get the path from the request, via the store.
  my $ofr  = $pipe->store->get('OpenFrame::Request');
  if (!$ofr) {
    $self->emit("no OpenFrame::Request available in store");
    return undef;
  }

  my $path = $ofr->uri->path();

  # add the images directory
  my ($volume, $dirs, $file) = File::Spec->splitpath( $path );
  my $realfile = File::Spec->catfile( $self->directory, $dirs, $file );

  $self->emit("trying to access $realfile");

  return unless -f $realfile;
  return unless -r _;

  my $mm = File::MMagic->new();
  my $type = $mm->checktype_filename($realfile);
  $self->emit("found type: $type");

  return unless $type =~ m:^image/:;

  $self->emit("serving image");

  my $fh = IO::File->new($realfile);
  my $data = join('', <$fh>);

  my $response = OpenFrame::Response->new();
  $response->code(ofOK());
  $response->message($data);
  $response->mimetype($type);
  return $response;
}


1;

__END__

=head1 NAME

OpenFrame::AppKit::Segment::Images - a pipeline segment to manage images

=head1 SYNOPSIS

  use OpenFrame::AppKit;
  my $images_engine = OpenFrame::Segment::Images->new();
  $images_engine->directory("./images");

=head1 DESCRIPTION

The C<OpenFrame::AppKit::Segment::Images> class is a pipeline segment
and inherits its interface from there. It provides additional
interface in the form of the director() method, which gets and sets
the root template directory that the template engine will examine.

=head1 AUTHOR

Leon Brocard <leon@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd. All Rights Reserved

This program is released under the same license as Perl itself.


