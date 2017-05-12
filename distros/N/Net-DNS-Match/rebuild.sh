make realclean
rm MANIFEST
rm *.tar.gz
perl Makefile.PL
make manifest
make dist
