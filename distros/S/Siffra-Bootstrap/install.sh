#!/usr/bin/env bash

clear
perl Makefile.PL && make && make manifest && make test && sudo make install && make realclean
