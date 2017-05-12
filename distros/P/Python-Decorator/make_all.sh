#!/bin/sh

rm MANIFEST
rm META.yml
rm -rf Python-Decorator-*

perl Makefile.PL
make
make manifest
make distdir
make disttest
make tardist
make clean
