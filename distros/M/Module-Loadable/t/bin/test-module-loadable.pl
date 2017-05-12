#!perl

use Module::Loadable qw(module_loadable);
require Local::Foo;

print module_loadable("Local::Foo") ? "l1":"L1";
print "\n";
print module_loadable("Local::Bar") ? "l2" : "L2";
print "\n";
print module_loadable("Local::Baz") ? "l3" : "L3";
print "\n";
