#!/bin/sh

set -e
set -v

mkdir repos

p4d -r `pwd`/repos &

sleep 5
mkdir checkout
mkdir checkout/test
mkdir checkout/test-branch

cat <<EOF | p4 client -i
Client: dan-laptop

Update: 2005/03/13 13:52:54

Access: 2005/03/13 13:52:55

Owner:  dan

Host:   localhost.localdomain

Description:
        Created by dan.

Root:   /home/dan/cvs/autobuild/testautobuild/t/scratch/checkout

Options:        noallwrite noclobber nocompress unlocked nomodtime normdir

LineEnd:        local

View:
        //depot/test/trunk/... //dan-laptop/test/...
        //depot/test/branch/... //dan-laptop/test-branch/...
EOF

cd checkout

echo 0 > test/a
perl -e 'print "1h ", time, "\n";' >> revs.txt

p4 add test/a
p4 submit

sleep 10

p4 edit test/a
echo 1 > test/a
p4 submit test/a
perl -e 'print "1h ", time, "\n";' >> ../revs.txt

sleep 10

p4 edit test/a
echo 2 > test/a
p4 submit test/a
perl -e 'print "2h ", time, "\n";' >> ../revs.txt

sleep 10

p4 integrate test/... test-branch/...
p4 submit
p4 sync

p4 edit test-branch/a
echo 3 > test-branch/a
p4 submit test-branch/a
perl -e 'print "3b ", time, "\n";' >> ../revs.txt

sleep 10

p4 edit test/a
echo 4 > test/a
p4 submit test/a
perl -e 'print "4h ", time, "\n";' >> ../revs.txt

sleep 10

p4 edit test-branch/a
echo 5 > test-branch/a
p4 submit test-branch/a
perl -e 'print "5b ", time, "\n";' >> ../revs.txt

p4 edit test/a
echo 6 > test/a
p4 submit test/a
perl -e 'print "6h ", time, "\n";' >> ../revs.txt

