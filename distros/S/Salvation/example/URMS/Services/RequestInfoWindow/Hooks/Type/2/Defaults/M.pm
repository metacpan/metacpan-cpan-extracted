use strict;

package URMS::Services::RequestInfoWindow::Hooks::Type::2::Defaults::M;

use Moose;

extends 'URMS::Services::RequestInfoWindow::Defaults::M';

 sub raw_serial_number
 {
        my ( $self, $object ) = @_;

        my $serial_number = $object -> { 'serial_number' };

        $serial_number =~ s/^(..).+?(..)$/${1}XX-XXXX-XX${2}/;

        return $serial_number;
 }

no Moose;

-1;


