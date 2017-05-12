package Net::Journyx::Subsubcode;
use Moose;
# XXX: do we want to extend Subcode? At this point questionable
extends 'Net::Journyx::Code';

use constant jx_record_class => 'SubsubcodeRecord';
use constant jx_meta => {
    defaults => 'getDefaultSubsubcode',
    load => 'getSubsubcode',
    update => {
        operation       => 'modifySubsubcode',
        leading         => 'id',
        leading_argname => 'id',
        record_argname  => 'rec',
    },
    create => {
        operation => 'addFullSubsubcode',
# According to WSDL file addSubsubcode takes 'name' and CodeRecord has pretty_name column,
# but we get the following error:
#     There are problems with 1 columns in your record:
#     The column codes_tasks.pname is not allowed to have the null value. []
#
# Let's disable quick create
#        quick     => {
#            operation => 'addSubsubcode',
#            columns   => [qw(pretty_name)],
#            rewrite   => { pretty_name => 'name' },
#        }
    },
    delete => {
        operation       => 'removeSubsubcode',
        leading         => 'id',
        leading_argname => 'id',
    },
};

1;
