# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl pod.t'
# Without Makefile it could be called with `perl -I../lib pod.t'.
# This is also the command needed to find out what specific tests
# failed in a `make test' as the later only gives you a number and not
# the description of the test.

#########################################################################

use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
