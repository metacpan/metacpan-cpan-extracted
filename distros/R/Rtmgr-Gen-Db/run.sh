#!/bin/bash
make clean
perl Makefile.PL
prove -l -t
make test
make install
make clean
