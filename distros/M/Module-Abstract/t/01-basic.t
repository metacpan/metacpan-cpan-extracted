#!perl

use strict;
use warnings;
use Test::More 0.98;

use Module::Abstract qw(module_abstract);

is(module_abstract("Module::Abstract"), "Extract the abstract of a locally installed Perl module");

done_testing;
