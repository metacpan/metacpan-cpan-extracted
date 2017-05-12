#!/bin/sh

set -e
set -v

sleep=10

rm -rf scratch
mkdir scratch
cd scratch

base=`pwd`
repos=$base/repos

mkdir checkout

arch="test2@autobuild.org--unittest"

tla register-archive --delete $arch || :
tla make-archive $arch $repos
tla archive-setup -A $arch test--main--1.0

cd checkout
echo 0 > a
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

tla init-tree -A $arch test--main--1.0
tla add a
tla import -s "Initial import"

sleep $sleep

echo 1 > a
tla commit -s 'Change 1'
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep $sleep

echo 2 > a
tla commit -s 'Change 2'
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep $sleep

tla archive-setup -A $arch test--branch--1.0
tla tag -A $arch $arch/test--main--1.0--patch-2 test--branch--1.0

cd ..
tla get -A $arch test--branch--1.0 branch
cd branch

echo 3 > a
tla commit -s 'Change 3'
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep $sleep

cd ../checkout

echo 4 > a
tla commit -s 'Change 4'
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep $sleep

cd ../branch

echo 5 > a
tla commit -s 'Change 5'
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

cd ../checkout

echo 6 > a
tla commit -s 'Change 6'
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

