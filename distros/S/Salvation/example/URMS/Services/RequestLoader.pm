use strict;

package URMS::Services::RequestLoader;

use Moose;

extends 'Salvation::Service';

 sub main
 {
        my $self = shift;

        $self -> system() -> storage() -> put( request => $self -> dataset() -> first() );

        return;
 }

no Moose;

-1;


