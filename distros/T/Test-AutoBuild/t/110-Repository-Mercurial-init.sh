#!/bin/sh

set -v
set -e

SLEEP=10

rm -rf scratch
mkdir scratch
cd scratch

mkdir repos
mkdir repos/trunk

cd repos
hg init trunk

cd trunk

echo 0 > a
perl -e 'print "0h ", time, "\n";' >> ../revs.txt

hg addremove
hg commit -m 'Initial import'

sleep $SLEEP

echo 1 > a
hg ci -m 'Change 1 on trunk' a
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

echo 2 > a
hg ci -m 'Change 2 on trunk' a
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

cd ..

hg clone trunk branch

sleep $SLEEP

cd branch
echo 3 > a
hg ci -m 'Change 3 on branch' a
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep $SLEEP

cd ../trunk

hg pull ../branch
hg update
sleep $SLEEP

echo 4 > a
hg ci -m 'Change 4 on trunk' a
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

cd ../branch
echo 5 > a
hg ci -m 'Change 5 on branch' a
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

cd ../trunk
hg pull ../branch
hg update -m
sleep $SLEEP

echo 6 > a
hg ci -m 'Change 6 on trunk' a
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

