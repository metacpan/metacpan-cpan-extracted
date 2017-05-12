#!perl -T
use strict;
use warnings;
use Test::More;


# public API
my $module = "POE::Component::Client::BigBrother";

my @exported_functions = ();
my @class_methods = qw< send >;

# tests plan
plan tests => 1
            + 2 * @exported_functions
            + 1 * @class_methods;

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

