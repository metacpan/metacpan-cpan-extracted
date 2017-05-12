package Silki::Role::Controller::File;
{
  $Silki::Role::Controller::File::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;

sub _serve_image {
    my $self = shift;
    my $c    = shift;
    my $file = shift;
    my $meth = shift;

    my $image = $file->$meth();

    $c->response()->status(200);
    $c->response()->content_type( $file->mime_type() );
    $c->response()->content_length( -s $image );
    $c->response()->header( 'X-Sendfile' => $image );

    $c->detach();
}

1;
