#!/bin/sh
# set up container to build Sys::OsPackage
# written for issue GH-1 https://github.com/ikluft/Sys-OsPackage/issues/1

# function to print error message and exit
die() {
    echo "container error: $*" >&2
    exit 1
}

# check container environment variables
if [ -z "$SYS_OSPKG_TIMESTAMP" ]
then
    die "environment variable SYS_OSPKG_TIMESTAMP must be set"
fi

# set environment variables for build
TMPDIR="/opt/container/logs/$SYS_OSPKG_TIMESTAMP"
HOME="$TMPDIR"
SYS_OSPACKAGE_DEBUG=1
export TMPDIR HOME SYS_OSPACKAGE_DEBUG

# check if container filesystem is set up
if [ ! -d "$TMPDIR" ]
then
    die "$TMPDIR directory missing from container environment"
fi
# shellcheck disable=SC2012
num_tarballs="$(ls -1 Sys-OsPackage-*.tar.gz | wc -l)"
if [ "$num_tarballs" -eq 0 ]
then
    die "Sys-OsPackage tarball file required: not found"
fi
# shellcheck disable=SC2012
tarball="$(ls -t Sys-OsPackage-*.tar.gz | head -1)"
srcdir="$(basename "$tarball" .tar.gz)"

# unpack Sys::OsPackage
tar -xf "$tarball"
if [ -n "$SYS_OSPKG_TEST_CONTENTS" ]
then
    echo "working directory contents:"
    echo "id in container: $(id)"
    tree -aC
    echo "home=$HOME"
    ls -laZ "$HOME"
else
    echo "home=$HOME"
fi
echo
echo "cd to $srcdir"
cd "$srcdir" || die "cd to $srcdir failed"

# interactive shell to inspect environment, if requested
if [ -n "$SYS_OSPKG_TEST_INTERACTIVE" ]
then
    bash -il -o vi
fi

# install dependencies
echo install dependencies with cpanm
cpanm --installdeps .

# build Sys::OsPackage and run tests
echo build
perl Build.PL || die Build.PL failed
perl Build || die build failed
echo run test
perl Build test || die test failed
exit $?
