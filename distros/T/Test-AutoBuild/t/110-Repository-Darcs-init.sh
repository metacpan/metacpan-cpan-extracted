#!/bin/sh

set -v
set -e

SLEEP=10

rm -rf scratch
mkdir scratch
cd scratch

mkdir repos
mkdir repos/trunk

cd repos/trunk
darcs initialize
echo "Fred Bloggs <fred@example.org>" > _darcs/prefs/author


echo 0 > a
perl -e 'print "0h ", time, "\n";' >> ../revs.txt

darcs add a
darcs record -am 'Initial import'

sleep $SLEEP

echo 1 > a
darcs record -am 'Change 1 on trunk' a
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

echo 2 > a
darcs record -am 'Change 2 on trunk' a
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

cd ..

darcs get trunk branch

sleep $SLEEP

cd branch
echo "Fred Bloggs <fred@example.org>" > _darcs/prefs/author
echo 3 > a
darcs record -am 'Change 3 on branch' a
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep $SLEEP

cd ../trunk

darcs pull -a ../branch
sleep $SLEEP

echo 4 > a
darcs record -am 'Change 4 on trunk' a
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep $SLEEP

cd ../branch
echo 5 > a
darcs record -am 'Change 5 on branch' a
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

cd ../trunk
darcs pull -a ../branch
sleep $SLEEP

echo 6 > a
darcs record -am 'Change 6 on trunk' a
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

