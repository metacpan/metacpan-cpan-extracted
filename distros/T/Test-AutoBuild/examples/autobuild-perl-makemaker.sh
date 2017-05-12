#!/bin/sh

NAME="Test-AutoBuild"

TEST_RESULTS=$1
test -z "$TEST_RESULTS" && TEST_RESULTS=results.log

# Exit immediately if command fails
set -e

# Print command executed to stdout
set -v

AUTOBUILD_PERL5LIB=`perl -e 'use Config; my $dir = $Config{sitelib}; $dir =~ s|/usr|$ENV{AUTOBUILD_INSTALL_ROOT}|; print $dir'`
if [ -z "$PERL5LIB" ]; then
  export PERL5LIB=$AUTOBUILD_PERL5LIB
else
  export PERL5LIB=$PERL5LIB:$AUTOBUILD_PERL5LIB
fi

# Make things clean.

[ -f Makefile ] && make -k realclean ||:
rm -rf MANIFEST blib

# Make makefiles.

perl Makefile.PL PREFIX=$AUTOBUILD_INSTALL_ROOT
make manifest
echo $NAME.spec >> MANIFEST

# Build the RPM.
make
if [ -n "$HTMLURLPREFIX" ]
then
  make htmlifypods HTMLURLPREFIX=$HTMLURLPREFIX
fi

if [ -z "$USE_COVER" ]; then
  perl -MDevel::Cover -e '' 1>/dev/null 2>&1 && USE_COVER=1 || USE_COVER=0
fi
rm -f test.log
if [ -z "$SKIP_TESTS" -o "$SKIP_TESTS" = "0" ]; then
  if [ "$USE_COVER" = "1" ]; then
    cover -delete
    rm -rf coverage-report
    set -o pipefail
    HARNESS_PERL_SWITCHES=-MDevel::Cover make test TEST_VERBOSE=1 | tee $TEST_RESULTS
    cover
    mkdir coverage-report
    mv cover_db/*.html cover_db/*.css coverage-report
    mv coverage-report/coverage.html coverage-report/index.html
    rm -rf cover_db
  else
    set -o pipefail
    make test TEST_VERBOSE=1 | tee $TEST_RESULTS
  fi
fi


make INSTALLMAN3DIR=$AUTOBUILD_INSTALL_ROOT/share/man/man3 install

rm -f $NAME-*.tar.gz
make dist

if [ -x /usr/bin/rpmbuild ]; then
  if [ -n "$AUTOBUILD_COUNTER" ]; then
    EXTRA_RELEASE=".auto$AUTOBUILD_COUNTER"
  else
    NOW=`date +"%s"`
    EXTRA_RELEASE=".$USER$NOW"
  fi
  rpmbuild -ta --define "extra_release $EXTRA_RELEASE" --clean $NAME-*.tar.gz
fi

if [ -x /usr/bin/fakeroot -a -f /etc/debian_version ]; then
  fakeroot debian/rules clean
  fakeroot debian/rules DEBDIR=$AUTOBUILD_PACKAGE_ROOT/debian binary
fi
