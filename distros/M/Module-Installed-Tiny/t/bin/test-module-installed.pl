#!perl

use Module::Installed::Tiny qw(module_installed);
require Local::Foo;

print module_installed("Local::Foo") ? "installed1":"NOT-INSTALLED1";
print "\n";
print module_installed("Local::Bar") ? "installed2" : "NOT-INSTALLED2";
print "\n";
print module_installed("Local::Baz") ? "installed3" : "NOT-INSTALLED3";
print "\n";
