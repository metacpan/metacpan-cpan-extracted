#!/bin/bash
set -e

CMDNAME=`basename $0`
RELEASE=$1

if [ ! $RELEASE ]; then
    echo "Usage: $CMDNAME release_branch_name" 1>&2
    exit 1
fi

if [ $(git branch --show-current) != $RELEASE ]; then
    echo -e "\033[31mError: must be $RELEASE branch when releasing\033[00m" 1>&2
    exit 1
fi
