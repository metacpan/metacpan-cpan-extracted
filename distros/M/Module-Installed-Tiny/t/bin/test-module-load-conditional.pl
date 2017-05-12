#!perl

use Module::Load::Conditional qw(check_install);
require Local::Foo;

print check_install(module => "Local::Foo") ? "loadable1":"UNLOADABLE1";
print "\n";
print check_install(module => "Local::Bar") ? "loadable2" : "UNLOADABLE2";
print "\n";
print check_install(module => "Local::Baz") ? "loadable3" : "UNLOADABLE3";
print "\n";
