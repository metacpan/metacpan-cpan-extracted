#!/bin/bash

CWD=`pwd`

PERL5LIB_SET=`/bin/echo $PERL5LIB | /bin/grep Mojolicious-Plugin-ConfigSimple | wc -l`
if [ $PERL5LIB_SET -eq 0 ]
then export PERL5LIB="$CWD/local/lib/perl5:$PERL5LIB"
# else /bin/echo 'PERL5LIB has already been set: ' && /bin/echo $PERL5LIB
fi

PATH_SET=`/bin/echo $PATH | /bin/grep Mojolicious-Plugin-ConfigSimple | wc -l`
if [ $PATH_SET -eq 0 ]
then
    export PATH="$CWD/local/bin:$PATH"
# else /bin/echo 'PATH has already been set: ' && /bin/echo "$PATH_SET : $PATH"
fi

