#!/bin/sh
BASEDIR=$(dirname $0)
perl -pi -E 's%^\#\!.+$%use lib "t";\nuse Panda::next;%' $BASEDIR/perl/*
perl -pi -E "s/chdir 't' if -d 't';//" $BASEDIR/perl/*
perl -pi -E 's#./test.pl#test.pl#' $BASEDIR/perl/*
