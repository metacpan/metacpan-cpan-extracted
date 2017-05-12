#!/bin/sh

make realclean
XCFLAGS=-fsanitize=address XLDLIBS=-lasan perl Makefile.PL
XCFLAGS=-fsanitize=address make
make test
