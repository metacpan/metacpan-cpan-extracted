#!/bin/bash

if [ ! -z $MYRIAD_DEV ]
then
    myriad-dev.pl $@
else
    myriad.pl $@
fi
