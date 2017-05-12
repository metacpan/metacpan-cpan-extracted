use strict;

package URMS::Services::RequestLoader::DataSet;

use Moose;

extends 'Salvation::Service::DataSet';

 sub main
 {
        my $self = shift;

        my $object = {
                id => 42,
                title => 'The Question',
                product => 100500, # magic number irrelevant to example
                serial_number => 'QWER-TYUI-OPAS', # magic string irrelevant to example
                type => 2, # magic number representing type of request
                comment => 'Why I even bought your product?'
        };

        return [
                ( $self -> service() -> system() -> request_id() == $object -> { 'id' } ? (
                        $object
                ) : () )
        ];
 }

no Moose;

-1;


