#!/usr/bin/env bash

TESTS=$@

if [ -z "$TESTS" ]; then
  TESTS=$(ls -1 ./t)
fi

rm -rf blib > /dev/null 2>&1
mkdir -p blib/lib/auto/share/dist/OpenMP-Simple/
cp -f share/openmp-simple.h blib/lib/auto/share/dist/OpenMP-Simple/openmp-simple.h
cp -f share/ppport.h blib/lib/auto/share/dist/OpenMP-Simple/ppport.h
EXIT=0
for FILE in $TESTS; do
  PERL_DL_NONLAZY=1 perl -Ilib -MExtUtils::Command::MM -MTest::Harness -e "undef *Test::Harness::Switches; test_harness(1, 'blib/lib', 'blib/arch')" t/$FILE
  if [ $? != 0 ]; then
    EXIT=$(($EXIT+1))
  fi
done

exit $EXIT
