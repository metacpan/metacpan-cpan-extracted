#!/bin/bash
set -euxo pipefail
# Can pass things like "--release" or "--verbose"

VERBOSE=""
RELEASE=""
for arg in "$@";
do
 if [[ $arg =~ "verbose" ]];
 then 
   VERBOSE="--verbose"
 fi

  if [[ $arg =~ "release" ]];
 then 
   RELEASE="--release"
 fi
done
docker run --rm -v "$PWD":/tmp  perldocker/perl-tester bash t/docker.sh "$VERBOSE" "$RELEASE"