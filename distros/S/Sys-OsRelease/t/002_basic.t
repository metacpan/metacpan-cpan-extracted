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

use Test::More;                      # last test to print

my @std_attrs = Sys::OsRelease::std_attrs();
plan tests => (22 + 3 * scalar @std_attrs);

{
    # instantiation (3 tests)
    is(Sys::OsRelease->defined_instance(), 0, "instance undefined before initialization");
    my $osrelease = Sys::OsRelease->instance();
    isa_ok($osrelease, "Sys::OsRelease", "correct type from instance()");
    my $osrelease2 = Sys::OsRelease->instance();
    is($osrelease, $osrelease2, "same instance from 2nd call to instance()");

    # module data (9+std_attrs tests)
    my @std_search_path = Sys::OsRelease::std_search_path();
    ok(scalar @std_search_path > 0, "std_search_path() returned non-empty list");
    ok(scalar @std_attrs > 0, "std_attrs() returned non-empty list");
    foreach my $attr (map {lc $_} @std_attrs) {
        ok($osrelease->can($attr), "ref->$attr() method found");
        ok(Sys::OsRelease->can($attr), "class->$attr() method found");
    }
    is($osrelease->has_config("platform"), 0, "before calling platform(): ref->has_attr(platform) is false");
    is(Sys::OsRelease->has_config("platform"), 0, "before calling platform(): class->has_attr(platform) is false");
    my $platform1 = $osrelease2->platform();
    my $platform2 = Sys::OsRelease->platform();
    is($osrelease->has_config("platform"), 1, "after calling platform(): ref->has_attr(platform) is true");
    is(Sys::OsRelease->has_config("platform"), 1, "after calling platform(): class->has_attr(platform) is true");
    ok((defined $platform1)?1:0, "ref->platform() returns a value"); # actual value reflects system running test
    ok((defined $platform2)?1:0, "class->platform() returns a value"); # actual value reflects system running test
    ok($platform1 eq $platform2, "ref->platform() and class->platform() return the same value");

    # check if os-release exists on the system performing the tests (2 tests)
    # alternate tests are given for whether os-release file exists or not on the system performing the test
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
Sys::OsRelease->clear_instance();
is(Sys::OsRelease->defined_instance(), 0, "cleared: instance undefined after clear_instance()");
my $osrelease3 = Sys::OsRelease->instance();
isa_ok($osrelease3, "Sys::OsRelease", "cleared: instance set again by instance()");

# test for empty object if os-release file wasn't found - set empty search path to force test (6+std_attrs tests)
Sys::OsRelease->clear_instance();
foreach my $attr (map {lc $_} @std_attrs) {
    ok((Sys::OsRelease->can($attr))?0:1, "empty: $attr() method does not exist");
}
my $osrelease4 = Sys::OsRelease->instance(search_path => []);
isa_ok($osrelease4, "Sys::OsRelease", "empty: instance set again by instance()");
ok(exists $osrelease4->{_config}, "empty: config exists");
ok((exists $osrelease4->{_config}{osrelease_path}) ? 0 : 1, "empty: _config/osrelease_path does not exist");
is(scalar keys %$osrelease4, 1, "empty: total keys = 1 including _config");
is($osrelease4->platform(), $Config{osname}, "empty: ref->platform() returns Perl's osname ($Config{osname})");
is(Sys::OsRelease->platform(), $Config{osname}, "empty: class->platform() returns Perl's osname ($Config{osname})");
