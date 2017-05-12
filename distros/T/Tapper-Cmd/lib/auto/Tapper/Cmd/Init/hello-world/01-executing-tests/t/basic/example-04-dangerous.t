#! /bin/bash

# Skip rest of script on neccessary condition

. ./tapper-autoreport --import-utils

require_crit_level 2

echo "# (example) danger area here - reached only with CRITICALITY=2 or higher"
grep -q DANGEROUS_ACTION /proc/cpuinfo

. ./tapper-autoreport

