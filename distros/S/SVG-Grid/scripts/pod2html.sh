#!/bin/bash
#
# $DR is my web server's doc root within Debian's RAM disk :-).
# The latter is at /run/shm, so $DR is /run/shm/html.

DIR=Perl-modules/html/SVG
FILE=Grid

mkdir -p $DR/$DIR

pod2html.pl -i lib/SVG/$FILE.pm -o $DR/$DIR/$FILE.html

cp -r $DR/$DIR ~/savage.net.au/$DIR
