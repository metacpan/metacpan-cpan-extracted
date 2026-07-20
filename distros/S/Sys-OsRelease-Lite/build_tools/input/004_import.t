#===============================================================================
#         FILE: 004_import.t
#  DESCRIPTION: test import of singleton management methods
#       AUTHOR: Ian Kluft (IKLUFT)
#      CREATED: 04/30/2022 06:17:49 PM
#===============================================================================

use strict;
use warnings;
use Sys::OsRelease;
use Test::More;

# configuration
my @import_methods = qw(init new instance defined_instance clear_instance);
plan tests => 3 * scalar @import_methods;

# pre-import tests: functions should not exist
{
    foreach my $method (@import_methods) {
        my $result = main->can($method);
        ok(! defined $result, "pre-import: $method should not exist");
    }
}

# do import
Sys::OsRelease->import_singleton();

# postimport tests: functions should exist
{
    foreach my $method (@import_methods) {
        my $result = main->can($method);
        ok(defined $result, "pre-import: $method defined");
        isa_ok($result, "CODE", "pre-import: $method");
    }
}

