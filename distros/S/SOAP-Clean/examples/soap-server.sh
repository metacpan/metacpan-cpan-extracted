#! /bin/bash

# This file is placed in the public domain.

set -- `getopt x:y:s: $*`
if [ $? != 0 ] ; then
    echo 'Usage: ...'
    exit 2
fi

X=""
Y=""
S=5
while [ "$*" ] ; do
    case "$1" in
    -s) S=$2; shift; shift ;;
    -x) X="`cat $2`"; shift; shift ;;
    -y) Y=$2; shift; shift ;;
    --) shift; break
    esac
done

W=$1
OUT1=$2
OUT2=$3

sleep $S

echo $[$X + $Y]
echo $[$X - $Y] > $OUT1
cat $W > $OUT2

exit 0
