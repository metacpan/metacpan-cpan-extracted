# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * 
TFILE=dbms-`date +%Y-%m-%d`

all: 
	( cd deamon; make )
	( cd libdbms; make )
	( cd dbmsproxy; make )
	( cd client; perl Makefile.PL && make )

tar:	clean
	if [ -f client/Makefile ] ; then ( cd client; make realclean ); fi
	( cd deamon; make clean )
	mkdir -p ../$(TFILE) 
	cp -r . ../$(TFILE)
	cd ..
	tar zcf $(TFILE).tar.gz $(TFILE)

test:
	( cd deamon; make test )

clean:
	( cd deamon; make clean )
	( cd libdbms; make clean )
	( cd dbmsproxy; make clean )
	( cd client; make realclean )

install: all
	( cd deamon; make install )
	( cd dbmsproxy; make install )
	( cd libdbms; make install )

depend:
	( cd deamon; make depend )
