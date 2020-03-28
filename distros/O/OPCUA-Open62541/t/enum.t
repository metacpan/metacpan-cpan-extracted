# Check that the automatically generated Perl constants from enum
# work correctly.  Use samples to test.

use strict;
use warnings;
use OPCUA::Open62541 qw(:ATTRIBUTEID
    ORDER_LESS ORDER_EQ ORDER_MORE
    VARIANT_DATA VARIANT_DATA_NODELETE);

use Test::More tests => 12;
use Test::NoWarnings;

# UA_AttributeId starts at 1 and explicitly specifies all values
cmp_ok(ATTRIBUTEID_NODEID, '==', 1, "attributeid first");
cmp_ok(ATTRIBUTEID_USEREXECUTABLE, '==', 22, "attributeid last");

# UA_RuleHandling increments value after explicit 0
cmp_ok(OPCUA::Open62541::RULEHANDLING_DEFAULT, '==', 0, "rulehandling default");
cmp_ok(OPCUA::Open62541::RULEHANDLING_ABORT,   '==', 1, "rulehandling abort");
cmp_ok(OPCUA::Open62541::RULEHANDLING_WARN,    '==', 2, "rulehandling warn");
cmp_ok(OPCUA::Open62541::RULEHANDLING_ACCEPT,  '==', 3, "rulehandling accept");

# UA_Order specifies negative value
cmp_ok(ORDER_LESS, '==', -1, "order less");
cmp_ok(ORDER_EQ  , '==',  0, "order eq");
cmp_ok(ORDER_MORE, '==',  1, "order more");

# UA_VariantStorageType enum starts implcitly with 0
cmp_ok(VARIANT_DATA,          '==',  0, "variant data");
cmp_ok(VARIANT_DATA_NODELETE, '==',  1, "variant data nodelete");
