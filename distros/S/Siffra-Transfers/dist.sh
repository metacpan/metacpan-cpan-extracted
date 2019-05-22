#!/usr/bin/env bash

SEPARADOR="_***************************************************************************************************************"

clear
echo "perl Makefile.PL" $SEPARADOR
perl Makefile.PL
echo "make realclean" $SEPARADOR
make realclean
echo "perl Makefile.PL" $SEPARADOR
perl Makefile.PL
echo "make test" $SEPARADOR
make test
echo "make manifest" $SEPARADOR
make manifest
echo "make dist" $SEPARADOR
make dist
echo "make distcheck" $SEPARADOR
make distcheck
file=$(ls *.gz)
echo "cpan-upload" $SEPARADOR
cpan-upload $file
echo "make realclean" $SEPARADOR
make realclean