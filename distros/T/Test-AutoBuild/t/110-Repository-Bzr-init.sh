#!/bin/sh

set -v
set -e

SLEEP=10

rm -rf scratch
mkdir scratch
cd scratch

mkdir repos
mkdir repos/main

cd repos/main
bzr init

echo 0 > a
perl -e 'print "0h ", time, "\n";' >> ../revs.txt

bzr add a
bzr commit -m 'Initial import'

sleep $SLEEP

echo 1 > a
bzr commit -m 'Change 1 on trunk'
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

echo 2 > a
bzr commit -m 'Change 2 on trunk'
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep $SLEEP
bzr branch . wibble

sleep $SLEEP
cd wibble

echo 3 > a
bzr commit -m 'Change 3 on branch'
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep $SLEEP

cd ..

bzr merge wibble
sleep $SLEEP

echo 4 > a
bzr commit -m 'Change 4 on trunk'
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

cd wibble
echo 5 > a
bzr commit -m 'Change 5 on branch'
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

cd ..
bzr merge wibble ||:
sleep $SLEEP

echo 6 > a
bzr resolve a
bzr commit -m 'Change 6 on trunk'
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

