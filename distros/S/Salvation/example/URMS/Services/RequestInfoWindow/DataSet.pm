use strict;

package URMS::Services::RequestInfoWindow::DataSet;

use Moose;

extends 'Salvation::Service::DataSet';

 sub main
 {
        my $self = shift;

        my $object = $self -> service() -> system() -> storage() -> get( 'request' );

        return [
                ( defined( $object ) ? $object : () )
        ];
 }

no Moose;

-1;


