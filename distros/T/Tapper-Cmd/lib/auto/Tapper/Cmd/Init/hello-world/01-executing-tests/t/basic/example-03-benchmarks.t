#! /bin/bash

. ./tapper-autoreport --import-utils

ok 0 "example benchmarks"

sleeptime=$(/usr/bin/time -f %e sleep 3 2>&1)
bogomips=$(echo $(cat /proc/cpuinfo | grep -i bogomips | head -1 | cut -d: -f2))

# cheat in some random deviation - just for more impressive example values
bogomips=$(echo "$bogomips+$((RANDOM % 20))" | bc -l)

# simple yaml here, indent level2 by yourself:
append_tapdata "benchmarks:"
append_tapdata "  bogomips: ${bogomips:-0.0}"
append_tapdata "  sleeptime: $sleeptime"
append_tapdata "  settings_1:"
append_tapdata "    used_options: -foo -bar affe/zomtec.dat"
append_tapdata "    foo: 12.34"
append_tapdata "    bar: 9.75"
append_tapdata "  settings_2:"
append_tapdata "    used_options: -foo -bar affe/tiger.dat"
append_tapdata "    foo: 10.34"
append_tapdata "    bar: 7.75"

# Same data but utilizing the new BenchmarkAnything subsystem
append_tapdata "BenchmarkAnythingData:"
append_tapdata "  - NAME: hello-world.example.bogomips"
append_tapdata "    VALUE: ${bogomips:-0.0}"
append_tapdata "    sleeptime: $sleeptime"
append_tapdata "    foo: 12.34"
append_tapdata "    bar: 9.75"

done_testing
