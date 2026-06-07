perl md2pod.pl
make realclean
git rm -r --cached blib/
git rm --cached *.o *.dll LikeR.c Makefile MYMETA.*
rm Makefile.PL
make distcheck
dzil clean && dzil build && dzil release
