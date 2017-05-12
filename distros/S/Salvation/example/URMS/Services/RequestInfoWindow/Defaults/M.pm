use strict;

package URMS::Services::RequestInfoWindow::Defaults::M;

use Moose;

extends 'Salvation::Service::Model';

 sub __raw
 {
        my ( $self, $object, $column ) = @_;

        return $object -> { $column };
 }

 sub custom_type
 {
        my ( $self, $object ) = @_;

        my %table = (
                1 => 'regular',
                2 => 'specific'
        );

        return $table{ $object -> { 'type' } };
 }

no Moose;

-1;


