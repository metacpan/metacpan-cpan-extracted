#!/bin/sh
#
# This script is used to Test::AutoBuild (http://www.autobuild.org)
# to perform automated builds of the NoZone module

NAME=NoZone

set -e

test -e ./Build && ./Build realclean ||:
rm -rf MANIFEST blib pm_to_blib

perl Build.PL --install_path etc=$AUTOBUILD_INSTALL_ROOT/etc --install_base $AUTOBUILD_INSTALL_ROOT
perl perl-NoZone.spec.PL perl-NoZone.spec

rm -f MANIFEST

# Build the RPM.
./Build
./Build manifest
./Build install

rm -f $NAME-*.tar.gz
./Build dist

if [ -f /usr/bin/rpmbuild ]; then
  if [ -n "$AUTOBUILD_COUNTER" ]; then
    EXTRA_RELEASE=".auto$AUTOBUILD_COUNTER"
  else
    NOW=`date +"%s"`
    EXTRA_RELEASE=".$USER$NOW"
  fi
  rpmbuild --nodeps -ta --define "extra_release $EXTRA_RELEASE" --clean $NAME-*.tar.gz
fi
