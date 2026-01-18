#!/bin/bash
# Build the example Strada shared library

set -e

STRADA_ROOT="../../.."
STRADAC="$STRADA_ROOT/stradac"
RUNTIME="$STRADA_ROOT/runtime"

echo "Building math_lib.strada as shared library..."

# Compile Strada to C
$STRADAC math_lib.strada math_lib.c

# Compile C to shared library
gcc -shared -fPIC -rdynamic \
    -o libmath.so \
    math_lib.c \
    $RUNTIME/strada_runtime.c \
    -I$RUNTIME \
    -ldl -lm

echo "Built libmath.so"
ls -la libmath.so
