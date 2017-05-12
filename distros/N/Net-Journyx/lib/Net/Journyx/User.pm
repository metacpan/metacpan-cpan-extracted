package Net::Journyx::User;
use Moose;
extends 'Net::Journyx::Record';

use constant jx_record_class => 'UserRecord';
use constant jx_meta => {
    load => 'getUser',
    update => {
        operation       => 'modifyUser',
        leading         => 'id',
        leading_argname => 'id',
        record_argname  => 'rec',
    },
};

no Moose;

1;
