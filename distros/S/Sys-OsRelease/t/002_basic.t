#
#===============================================================================
#         FILE: 002_basic.t
#  DESCRIPTION: basic tests for Sys::OsRelease 
#       AUTHOR: Ian Kluft (IKLUFT)
#      VERSION: 1.0
#      CREATED: 04/25/2022 03:28:18 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Sys::OsRelease;
use Config;

use Test::More tests => 15;                      # last test to print

{
    # instantiation (3 tests)
    is(Sys::OsRelease::defined_instance(), 0, "instance undefined before initialization");
    my $osrelease = Sys::OsRelease->instance();
    isa_ok($osrelease, "Sys::OsRelease", "correct type from instance()");
    my $osrelease2 = Sys::OsRelease->instance();
    is($osrelease, $osrelease2, "same instance from 2nd call to instance()");

    # module data (2 tests)
    my @std_search_path = Sys::OsRelease::std_search_path();
    ok(scalar @std_search_path > 0, "std_search_path() returned non-empty list");
    my @std_attrs = Sys::OsRelease::std_attrs();
    ok(scalar @std_attrs > 0, "std_attrs() returned non-empty list");

    # check if os-release exists on the system performing the tests (3 tests)
    ok($osrelease->can("id"), "id() method exists");
    {
        my $osr_found;
        foreach my $dir (@std_search_path) {
            if ( -f "$dir/os-release" ) {
                $osr_found = "$dir/os-release";
                last;
            }
        }

        # alternate tests depending whether os-release file was found
        my $id = $osrelease->id();
        my $osrelease_path = $osrelease->osrelease_path();
        if ($osr_found) {
            ok((defined $id) ? 1 : 0, "id() returns a value when os-release exists");
            ok((defined $osrelease_path) ? 1 : 0, "osrelease_path() returns a value when os-release exists");
        } else {
            ok((defined $id) ? 0 : 1, "id() returns undef when os-release doesn't exist");
            ok((defined $osrelease_path) ? 0 : 1, "osrelease_path() returns undef when os-release doesn't exist");
        }
    }
}

# clear instance (2 tests)
Sys::OsRelease::clear_instance();
is(Sys::OsRelease::defined_instance(), 0, "cleared: instance undefined after clear_instance()");
my $osrelease3 = Sys::OsRelease->instance();
isa_ok($osrelease3, "Sys::OsRelease", "cleared: instance set again by instance()");

# test for empty object if os-release file wasn't found - set empty search path to force test (5 tests)
Sys::OsRelease::clear_instance();
my $osrelease4 = Sys::OsRelease->instance(search_path => []);
isa_ok($osrelease4, "Sys::OsRelease", "empty: instance set again by instance()");
ok(exists $osrelease4->{_config}, "empty: config exists");
ok((exists $osrelease4->{_config}{osrelease_path}) ? 0 : 1, "empty: _config/osrelease_path does not exist");
is(scalar keys %$osrelease4, 1, "empty: total keys = 1 including _config");
is($osrelease4->platform(), $Config{osname}, "empty: platform returns Perl config's osname (".$Config{osname}.")");
