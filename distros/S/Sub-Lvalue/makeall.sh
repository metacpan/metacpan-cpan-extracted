#!/bin/bash

rm -rf MANIFEST.bak MANIFEST Makefile.old && \
pod2text lib/Sub/Lvalue.pm > README && \
perl -i -lpne 's{^\s+$}{};s{^    ((?: {8})+)}{" "x(4+length($1)/2)}se;' README && \
perl Makefile.PL && \
rm *.tar.gz ; \
make manifest && \
perl -i -lne 'print unless /(?:\.tar\.gz$|^dist)/' MANIFEST && \
make clean && \
perl Makefile.PL && \
make && \
make test && \
make disttest && \
make dist && \
cp -f *.tar.gz dist/ && \
make clean && \
rm -rf MANIFEST.bak Makefile.old && \
echo "All is OK"
