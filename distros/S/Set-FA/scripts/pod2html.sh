#!/bin/bash
#
# $DR is my web server's doc root within Debian's RAM disk :-).
# The latter is at /run/shm, so $DR is /run/shm/html.

DIR=Perl-modules/html/Set
FILE=FA

mkdir -p $DR/$DIR ~/savage.net.au/$DIR

pod2html.pl -i lib/Set/$FILE.pm -o $DR/$DIR/$FILE.html
pod2html.pl -i lib/Set/$FILE/Element.pm -o $DR/$DIR/$FILE/Element.html

cp -r $DR/$DIR/$FILE ~/savage.net.au/$DIR
