#!/bin/bash
#
# Build a .rpm package for Term::CLI, using the pre-packaged
# debian packaging files in ./pkg/fedora.

if [[ ! -d ./pkg/fedora || ! -f Makefile.PL ]]; then
cat <<EOF >&2
** ERROR **

This script needs to be executed in the top-level source directory,
i.e. the one containing the "Makefile.PL" file and "pkg" directory.
EOF
fi

TOP=$(pwd)
trap "cd $TOP; rm -rf $TOP/.build" 0
trap 'echo "** Interrupted">&2; exit 1' 1 2 3 15

# Create a clean .build environment.
rm -rf $TOP/.build
mkdir $TOP/.build
mkdir -p $TOP/.build/rpm $TOP/.build/build $TOP/.build/buildroot

# Build a release tarball
perl Makefile.PL
make DISTVNAME=build dist

# Unpack release tarball in build directory.
mv $TOP/build.tar.gz $TOP/.build
cd $TOP/.build
tar -xzf build.tar.gz

cd $TOP/.build/build

# Build the package.
rpmbuild -bb \
    --define "_rpmdir $TOP/.build/rpm" \
    --define "_buildrootdir $TOP/.build/buildroot" \
    --build-in-place \
    ./pkg/fedora/perl-Term-CLI.spec

# Move the package to the current directory.
cd $TOP
rpmfile=$(find $TOP/.build/rpm -name 'perl-Term-CLI-*.rpm' -print)
mv $rpmfile $TOP/$(basename $rpmfile)

echo
echo '============================================================'
echo
echo "Current WD:" $TOP
echo "RPM file:  " $(basename $rpmfile)
echo
echo '============================================================'

exit 0
