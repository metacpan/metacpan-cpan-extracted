#git rm -r --cached blib/
#git rm --cached *.o *.dll LikeR.c Makefile MYMETA.*
make clean && perl Makefile.PL OPTIMIZE='-Wall' && make && make test && make install
