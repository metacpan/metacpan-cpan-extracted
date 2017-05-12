#! /bin/bash

KERNELFILE=$1

echo "1..3"

if [ -z "$KERNELFILE" ] ; then echo -n "not " ; fi
echo "ok - we got parameter for kernel file"

if [ ! -e "$KERNELFILE" ] ; then echo -n "not " ; fi
echo "ok - kernel file exists"

echo "# Installing kernel $KERNELFILE..."

# DO ACTUAL INSTALLATION HERE

echo "ok - kernel installed"
