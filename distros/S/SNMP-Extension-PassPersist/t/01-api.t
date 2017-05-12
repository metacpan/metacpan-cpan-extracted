#!perl -T
use strict;
use warnings;
use Test::More;
use lib "t/lib";


# public API
my $module = "SNMP::Extension::PassPersist";

my @exported_functions = qw(
);

my @class_methods = qw(
    new
);

my @object_methods = qw(
    backend_init
    backend_collect
    idle_count
    input
    oid_tree
    output
    refresh
    
    run
    add_oid_entry
    add_oid_tree
    ping
    get_oid
    getnext_oid
    set_oid
    process_cmd
    fetch_next_entry
    fetch_first_entry
);

my @creator_args = ();

# tests plan
plan tests => 1
            + 2 * @exported_functions
            + 1 * @class_methods
            + 2 + 2 * @object_methods;

# load the module
use_ok( $module );

# check functions
for my $function (@exported_functions) {
    can_ok($module, $function);
    can_ok(__PACKAGE__, $function);
}

# check class methods
for my $methods (@class_methods) {
    can_ok($module, $methods);
}

# check object methods
my $object = eval { $module->new(@creator_args) };
is( $@, "", "creating a $module object" );
isa_ok( $object, $module, "check that the object" );

for my $method (@object_methods) {
    can_ok($module, $method);
    can_ok($object, $method);
}

