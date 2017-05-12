#!/bin/sh

set -v
set -e

SLEEP=10

rm -rf scratch
mkdir scratch
cd scratch

mkdir repos
mkdir repos/trunk
mkdir repos/branch

cd repos
mtn db init --db trunk.db

cd trunk
mtn setup -d ../trunk.db --branch trunk .

echo 0 > a
perl -e 'print "0h ", time, "\n";' >> ../revs.txt

mtn add a
mtn commit -m 'Initial import'

sleep $SLEEP

echo 1 > a
mtn commit -m 'Change 1 on trunk'
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

echo 2 > a
mtn commit -m 'Change 2 on trunk'
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

echo 3 > a
mtn commit --branch=wibble -m 'Change 3 on branch'
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep $SLEEP

# Switch to trunk
mtn update -b trunk -r h:trunk
# Pull branch into trunk
mtn propagate wibble trunk
mtn update -b trunk -r h:trunk
sleep $SLEEP

echo 4 > a
mtn commit -m 'Change 4 on trunk'
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

mtn update -b wibble -r h:wibble
echo 5 > a

mtn commit --branch=wibble -m 'Change 5 on branch'
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

mtn update -b trunk -r h:trunk

mtn propagate wibble trunk
mtn update -b trunk -r h:trunk
sleep $SLEEP

echo 6 > a
mtn commit -m 'Change 6 on trunk'
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

