package Silki::Controller::UserImage;
{
  $Silki::Controller::UserImage::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema::UserImage;

use Moose;

BEGIN { extends 'Silki::Controller::Base' }

with 'Silki::Role::Controller::File';

sub _set_image : Chained('/') : PathPart('user_image') : CaptureArgs(1) {
    my $self    = shift;
    my $c       = shift;
    my $user_id = shift;

    my $image = Silki::Schema::UserImage->new( user_id => $user_id );

    $c->status_not_found()
        unless $image;

    $c->stash()->{image} = $image;
}

sub small_image : Chained('_set_image') : PathPart('small') : Args(0) {
    my $self = shift;
    my $c    = shift;
    my $user_id = shift;

    $self->_serve_image( $c, $c->stash()->{image}, 'small_image_file' );
}

sub thumbnail : Chained('_set_image') : PathPart('thumbnail') : Args(0) {
    my $self = shift;
    my $c    = shift;
    my $user_id = shift;

    $self->_serve_image( $c, $c->stash()->{image}, 'thumbnail_file' );
}

sub mini_image : Chained('_set_image') : PathPart('mini') : Args(0) {
    my $self = shift;
    my $c    = shift;
    my $user_id = shift;

    $self->_serve_image( $c, $c->stash()->{image}, 'mini_image_file' );
}

__PACKAGE__->meta()->make_immutable();

1;
