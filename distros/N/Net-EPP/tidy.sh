#!/bin/sh
# this runs perltidy for every script and then cleans up after itself

DIR="$(dirname "$0")"

find "$DIR" -iname '*.p[lm]' | xargs perltidy -b

find "$DIR" -iname '*.bak' -delete
