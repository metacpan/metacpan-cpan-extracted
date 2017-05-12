package Net::Journyx::Subcode;
use Moose;
extends 'Net::Journyx::Code';

use constant jx_record_class => 'SubcodeRecord';
use constant jx_meta => {
    defaults => 'getDefaultSubcode',
    load => 'getSubcode',
    update => {
        operation       => 'modifySubcode',
        leading         => 'id',
        leading_argname => 'id',
        record_argname  => 'rec',
    },
    create => {
        operation => 'addFullSubcode',
# According to WSDL file addSubcode takes 'name' and CodeRecord has pretty_name column,
# but we get the following error:
#     There are problems with 1 columns in your record:
#     The column codes_tasks.pname is not allowed to have the null value. []
#
# Let's disable quick create
#        quick     => {
#            operation => 'addSubcode',
#            columns   => [qw(pretty_name)],
#            rewrite   => { pretty_name => 'name' },
#        }
    },
    delete => {
        operation       => 'removeSubcode',
        leading         => 'id',
        leading_argname => 'id',
    },
};

1;
