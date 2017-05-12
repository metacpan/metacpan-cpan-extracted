#!/bin/sh

rm -rf scratch
mkdir scratch
cd scratch

base=`pwd`
repos=$base/repos

mkdir repos
mkdir import
mkdir checkout


cvs -d $repos init

echo 0 > import/a
perl -e 'print "1h ", time, "\n";' >> revs.txt

(
  cd import
  cvs -d $repos import -m 'Initial import' test start initial
)

cvs -d $repos co -d checkout test

cd checkout

sleep 10

echo 1 > a
cvs -d $repos ci -m 'Change 1' a
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep 10

echo 2 > a
cvs -d $repos ci -m 'Change 2' a
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep 10

cvs -d $repos tag -b 'branch' 
cvs -d $repos up -r 'branch'

echo 3 > a
cvs -d $repos ci -m 'Change 3' a
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep 10

cvs up -A

echo 4 > a
cvs -d $repos ci -m 'Change 4' a
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep 10

cvs -d $repos up -r 'branch'

echo 5 > a
cvs -d $repos ci -m 'Change 5' a
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

cvs up -A

echo 6 > a
cvs -d $repos ci -m 'Change 6' a
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

