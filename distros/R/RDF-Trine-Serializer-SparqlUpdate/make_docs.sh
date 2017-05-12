#!/bin/bash

HTMLDIR=blib/libhtml
PODDIR=lib

mkdir -p blib/libhtml

perl -MPod::Simple::HTMLBatch -e Pod::Simple::HTMLBatch::go $PODDIR $HTMLDIR

wget -O $HTMLDIR/_blkbluw.css search.cpan.org/s/style.css 
