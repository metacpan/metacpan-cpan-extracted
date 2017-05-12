#!/bin/sh
#
# bin/setup-test-data.sh - Setup test files.  
# MakeMaker doesn't handle files with spaces in their names.
#
# This is meant to be run from the t/ directory (or at any rate, a sibling of
# the test-data/ directory).

BASE="../test-data"

if [ ! -d "$BASE" ]; then
    echo "Error: '$BASE' does not exist"
    echo "Please run from module 't/' directory"
    exit 1
fi

mkdir "$BASE/test dir with spaces"
mkdir "$BASE/test-subdir"
mkdir "$BASE/test-subdir/dir-a"

touch "$BASE/test file with spaces"
touch "$BASE/empty-file"
touch "$BASE/test-subdir/file-a"
touch "$BASE/test-subdir/file-b"
touch "$BASE/test-subdir/file-c"
touch "$BASE/test-subdir/dir-a/file-a-a"


