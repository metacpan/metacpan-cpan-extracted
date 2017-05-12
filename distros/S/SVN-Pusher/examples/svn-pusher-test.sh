#!/bin/sh
mypath="`pwd`"
rm -fr test-repos-src
svnadmin create test-repos-src
svnadmin load test-repos-src < test-repos.dump
rm -fr test-repos-dest
svnadmin create test-repos-dest
svnadmin load test-repos-dest < test-repos.dump
rm -fr trunk
svn co file://`pwd`/test-repos-src/trunk
(cd trunk;
    echo "Yowza!" >> hello.txt
    svn commit -m "Yowza"
    echo "Hoola" > Something.txt
    echo "Yes" >> Something.txt
    svn add Something.txt
    svn commit -m "Adding Something"
)
if test "$SKIP_PUSHER" != "" ; then
    exit
fi
svn-pusher push --revision=4:6 file://`pwd`/test-repos-src file://`pwd`/test-repos-dest
# svn-pusher push --revision=4:6 http://localhost:8080/svn-pusher-test/src/trunk svn+ssh://shlomi@localhost`pwd`/test-repos-dest/trunk

# svn checkout file://"$mypath"/
