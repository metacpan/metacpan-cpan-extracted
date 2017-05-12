#!/bin/sh
#
# stats2page.sh
# version 1.01, 2-17-08
#

if [ $# -lt 3 ]; then
  echo
  echo usage: $0 src/path history/dest/path list/dest/file [optional]name
  echo
  exit
fi

if [ $# -eq 3 ]; then
  YEAR=`date +%Y`
  DAY=`date +%d`
  MON=`date +%m`
  NAME=${YEAR}-${MON}-${DAY}
else
  NAME=$4
fi

SRC=$1
HIST=$2
LIST=$3

FILE=${NAME}.html

scripts/stats2html.pl  $NAME $SRC > ${HIST}/$FILE

scripts/stats2list.pl $HIST > $LIST
