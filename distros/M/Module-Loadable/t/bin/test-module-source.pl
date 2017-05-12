#!perl

use Module::Loadable qw(module_source);
require Local::Foo;

print module_source("Local::Foo");
print "\n";
print module_source("Local::Bar");
print "\n";
