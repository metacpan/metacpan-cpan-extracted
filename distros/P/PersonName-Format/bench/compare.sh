#!/bin/sh
set -eu

ITERATIONS="${ITERATIONS:-1000}"
SUITE="${SUITE:-all}"

if [ ! -d blib ]; then
    perl Makefile.PL
    make
fi

printf '\n=== XS backend ===\n'
unset PERSONNAME_FORMAT_PUREPERL || true
perl -Mblib bench/format.pl --iterations "$ITERATIONS" --suite "$SUITE"

printf '\n=== Pure-Perl backend ===\n'
PERSONNAME_FORMAT_PUREPERL=1 perl -Mblib bench/format.pl \
    --iterations "$ITERATIONS" \
    --suite "$SUITE"
