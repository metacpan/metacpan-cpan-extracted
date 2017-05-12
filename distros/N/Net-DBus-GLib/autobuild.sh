#!/bin/sh
#
# This script is used by Test::AutoBuild (http://www.autobuild.org)
# to perform automated builds of the DBus module

NAME=Net-DBus-GLib

set -e

make -k realclean ||:
rm -rf MANIFEST blib pm_to_blib

perl Makefile.PL  PREFIX=$AUTOBUILD_INSTALL_ROOT

# Build the RPM.
make
make manifest

if [ -z "$USE_COVER" ]; then
  perl -MDevel::Cover -e '' 1>/dev/null 2>&1 && USE_COVER=1 || USE_COVER=0
fi

if [ -z "$SKIP_TESTS" -o "$SKIP_TESTS" = "0" ]; then
  if [ "$USE_COVER" = "1" ]; then
    cover -delete
    HARNESS_PERL_SWITCHES=-MDevel::Cover make test
    cover
    mkdir blib/coverage
    cp -a cover_db/*.html cover_db/*.css blib/coverage
    mv blib/coverage/coverage.html blib/coverage/index.html
  else
    make test
  fi
fi

make install

rm -f $NAME-*.tar.gz
make dist

if [ -f /usr/bin/rpmbuild ]; then
  if [ -n "$AUTOBUILD_COUNTER" ]; then
    EXTRA_RELEASE=".auto$AUTOBUILD_COUNTER"
  else
    NOW=`date +"%s"`
    EXTRA_RELEASE=".$USER$NOW"
  fi
  rpmbuild -ta --define "extra_release $EXTRA_RELEASE" --clean $NAME-*.tar.gz
fi

