use strict;

package URMS::Services::RequestInfoWindow::Defaults::V;

use Moose;

extends 'Salvation::Service::View';

 sub main
 {
        return [
                raw => [
                        'id',
                        'serial_number',
                        'title',
                        'comment'
                ],
                custom => [
                        'type'
                ]
        ];
 }

no Moose;

-1;


