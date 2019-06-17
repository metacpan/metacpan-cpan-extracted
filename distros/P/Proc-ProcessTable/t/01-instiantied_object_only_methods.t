# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test::More;
BEGIN { plan tests => 2 }

# check wether ProcProcessTable is there

use Proc::ProcessTable;

eval {
    Proc::ProcessTable->fields;
};
like( $@, qr/Must call fields from an initalized object created with new.*/, 'Uninitialized object 1' );

eval {
    Proc::ProcessTable->table;
};
like( $@, qr/Must call table from an initalized object created with new.*/, 'Uninitialized object 2' );


