#!perl -T
use strict;
use warnings;
use Test::More;


# public API
my $module    = "POE::Component::NetSNMP::agent";
my @functions = qw<
>;
my @class_methods = qw<
    spawn
>;
my @object_methods = qw<
    register  add_oid_entry  add_oid_tree
>;

my $tests = 1 + @functions + @class_methods
    + (@object_methods ? 2 + @object_methods : 0);


# test plan
plan tests => $tests;


# load module
use_ok($module);

# check functions
for my $function (@functions) {
    can_ok($module, $function);
}

# check class methods
if (@class_methods) {
    for my $method (@class_methods) {
        can_ok($module, $method);
    }
}

# check object methods
if (@object_methods) {
    my $constructor = $class_methods[0];
    my $object = eval { $module->$constructor };
    is( $@, "", "creating a $module object" );
    isa_ok( $object, $module, "check that the object" );

    for my $method (@object_methods) {
        can_ok($object, $method);
    }
}

POE::Kernel->stop();

