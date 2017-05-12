#! /bin/bash

# This file is placed in the public domain.

set -- `getopt x:y:s: $*`
if [ $? != 0 ] ; then
    echo 'Usage: ...'
    exit 2
fi

X=""
Y=""
while [ "$*" ] ; do
    case "$1" in
    -x) X=$2; shift; shift ;;
    -y) Y=$2; shift; shift ;;
    --) shift; break
    esac
done

echo $[$X + $Y]

exit 0
