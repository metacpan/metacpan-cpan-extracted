#!/bin/sh

#set -v

rm -rf scratch
mkdir scratch
cd scratch

base=`pwd`
repospath=$base/repos
repos=file://$repospath

mkdir repos
mkdir import
mkdir checkout


svnadmin create $repospath

echo 0 > import/a
perl -e 'print "1h ", time, "\n";' >> revs.txt

(
  cd import
  svn import -m 'Initial import' $repos/test/trunk
)

svn checkout $repos/test/trunk checkout

cd checkout

sleep 10

echo 1 > a
svn ci -m 'Change 1' a
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep 10

echo 2 > a
svn ci -m 'Change 2' a
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep 10

svn copy -m 'Branched code' $repos/test/trunk $repos/test/branch
svn switch $repos/test/branch .

echo 3 > a
svn ci -m 'Change 3' a
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep 10

svn switch $repos/test/trunk .

echo 4 > a
svn ci -m 'Change 4' a
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep 10

svn switch $repos/test/branch .

echo 5 > a
svn ci -m 'Change 5' a
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

svn switch $repos/test/trunk .

echo 6 > a
svn ci -m 'Change 6' a
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

