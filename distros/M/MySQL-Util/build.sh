rm -rf *.gz 
rm -rf MANIFEST* 

perl Makefile.PL && \
make && \
make test && \
make manifest && \
make dist
