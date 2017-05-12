#!/bin/sh
#
# mon2page.sh
# version 1.01, 2-17-08
#

if [ $# -lt 3 ]; then
  echo
  echo usage: $0 stats/src/path report/src/path history/dest/path list/dest/file [optional]name
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

SRC1=$1
SRC2=$2
HIST=$3
LIST=$4

FILE=${NAME}.html

scripts/mon2html.pl  $NAME $SRC1 $SRC2 > ${HIST}/$FILE

scripts/mon2list.pl $HIST > $LIST
