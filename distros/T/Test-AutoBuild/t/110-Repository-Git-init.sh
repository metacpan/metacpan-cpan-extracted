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
git init

echo 0 > a
perl -e 'print "0h ", time, "\n";' >> ../revs.txt

git add a
git commit -m 'Initial import'

sleep $SLEEP

echo 1 > a
git commit -a -m 'Change 1 on trunk'
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

echo 2 > a
git commit -a -m 'Change 2 on trunk'
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep $SLEEP
git-branch wibble

sleep $SLEEP
git-checkout wibble

echo 3 > a
git commit -a -m 'Change 3 on branch'
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep $SLEEP

git-checkout master

git-merge wibble
sleep $SLEEP

echo 4 > a
git commit -a -m 'Change 4 on trunk'
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

git-checkout wibble
echo 5 > a
git commit -a -m 'Change 5 on branch'
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

git-checkout master
git-merge --strategy=ours wibble
sleep $SLEEP

echo 6 > a
git commit -a -m 'Change 6 on trunk'
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

