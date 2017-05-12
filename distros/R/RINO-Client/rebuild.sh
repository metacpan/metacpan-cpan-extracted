make
make realclean
rm MANIFEST
rm META.yml
perl Makefile.PL
make manifest
make dist
