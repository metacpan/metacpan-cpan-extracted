use strict;

package URMS;

use Moose;

extends 'Salvation::System';

 sub BUILD
 {
        my $self = shift;

        my $constraint = sub
        {
                return $self -> request_page_constraint();
        };

        $self -> Service( $_, { constraint => $constraint } )
                for
                        'RequestLoader',
                        'RequestInfoWindow',
                        'UserInfoWindow',
                        'RequestMgmtControls'
        ;

        return;
 }

 sub request_id
 {
        my $self = shift;

        return $self -> args() -> { 'request_id' };
 }

 sub request_page_constraint
 {
        my $self = shift;

        return defined $self -> request_id();
 }

no Moose;

-1;


