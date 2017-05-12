package Net::Journyx::Code;
use Moose;
extends 'Net::Journyx::Record';

use constant jx_record_class => 'CodeRecord';
use constant jx_strip_record_suffix => 1;
use constant jx_meta => {
    defaults => 'getDefaultCode',
    load => 'getCode',
    update => {
        operation       => 'modifyCode',
        leading         => 'id',
        leading_argname => 'id',
        record_argname  => 'rec',
    },
    create => {
        operation => 'addFullCode',
# According to WSDL file addCode takes 'name' and CodeRecord has pretty_name column,
# but we get the following error:
#     There are problems with 1 columns in your record:
#     The column codes_tasks.pname is not allowed to have the null value. []
#
# Let's disable quick create
#        quick     => {
#            operation => 'addCode',
#            columns   => [qw(pretty_name)],
#            rewrite   => { pretty_name => 'name' },
#        }
    },
    delete => {
        operation       => 'removeCode',
        leading         => 'id',
        leading_argname => 'id',
    },
};

1;
