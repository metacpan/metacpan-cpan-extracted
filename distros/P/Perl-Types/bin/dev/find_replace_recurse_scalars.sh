#!/bin/bash

FIND_PREFIX=$1
echo "have FIND_PREFIX = '"$FIND_PREFIX"'"
FIND_DATA_STRUCTURE=$2
REPLACE_PREFIX=$3
REPLACE_DATA_STRUCTURE=$4

for DATA_TYPE in boolean integer number character string scalartype;
do
    echo $DATA_TYPE
    if [[ -z "$FIND_PREFIX" ]]; then
        FIND=$DATA_TYPE'_'$FIND_DATA_STRUCTURE
    else
        FIND=$FIND_PREFIX'_'$DATA_TYPE'_'$FIND_DATA_STRUCTURE
    fi
    echo $FIND
    if [[ -z "$REPLACE_PREFIX" ]]; then
        REPLACE=$REPLACE_DATA_STRUCTURE'_'$DATA_TYPE
    elif [[ -z "$REPLACE_DATA_STRUCTURE" ]]; then
        REPLACE=$REPLACE_PREFIX'_'$DATA_TYPE
    else
# NEED MANUALLY SWITCH BETWEEN INFIX AND POSTFIX AS NEEDED
#        REPLACE=$REPLACE_PREFIX'_'$REPLACE_DATA_STRUCTURE'_'$DATA_TYPE
        REPLACE=$REPLACE_PREFIX'_'$DATA_TYPE'_'$REPLACE_DATA_STRUCTURE
    fi
    echo $REPLACE
    find_replace_recurse.sh $FIND $REPLACE .
    echo PRESS ENTER TO CONTINUE...
    read -n 1 -s
done
