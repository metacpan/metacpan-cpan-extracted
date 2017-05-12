use strict;

package URMS::Services::RequestInfoWindow;

use Moose;

extends 'Salvation::Service';

 sub BUILD
 {
        my $self = shift;

        $self -> Hook( [ $self -> dataset() -> first() -> { 'type' }, 'Type' ] );

        return;
 }

no Moose;

-1;


