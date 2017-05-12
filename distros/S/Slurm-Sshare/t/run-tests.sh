#!/bin/sh

PERL=perl
#PERL=/homes/payerle/localhome/perl/bin/perl5.22.1

RELEASE_TESTING=1
export RELEASE_TESTING

cd ..
$PERL -I ./lib -MTest::Harness -e "runtests(<t/*.t>)"
