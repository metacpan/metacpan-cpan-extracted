#!/bin/sh
test="/opt/perl-5.10.1/bin/perl -d:NYTProf -Mblib"

if [[ -e nytprof.out ]]; then
    rm nytprof.out
fi
$test t/15hilite_diff.t
$test t/15watch.t
$test t/16hilite_diff.t

if [[ -e nytprof ]]; then
    rm -rf nytprof
fi

/opt/perl-5.10.1/bin/nytprofhtml
open nytprof/index.html
