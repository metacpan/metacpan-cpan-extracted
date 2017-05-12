#! /bin/bash

. ./tapper-autoreport --import-utils

# cpufeatures are looked up in /proc/cpuinfo::flags.

# the require_* functions stop the script in a controlled way
require_vendor_amd
require_cpufeature "msr"
require_cpufeature "fpu"
# require_amd_family_range 0xf 0x12
# require_cpufeature "cpb"
# require_amd_family_range 0x10

# store success in variables and make complex tests
if grep -q AMD /proc/cpuinfo ; then
    if grep -q sse2 /proc/cpuinfo ; then
        YAY=0
    else
        YAY=1
    fi
fi
# ok() evaluates arg 1 with exit code shell boolean semantics
# and creates TAP
ok $YAY "looks like AMD and SSE2"

# negate_ok() reverses the success semantics of ok()
grep -q zomtec /proc/cpuinfo
negate_ok $? "no zomtec no cry"

# mark tests with "# TODO" at end of description
negate_ok $YAY "example that fails expectedly # TODO some todo explanation"

# append complete TAP line (you also provide the ok / not ok)
append_tap "ok - The simplest of all tests"

# append key:value lines to track values
append_tapdata "number_of_tests: $(get_tap_counter)"

# actually create a test report
done_testing
