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
TFILE=`date +%Y-%m-%d`

include ../dbms/arch.conf

OBJS = ../dbms/libdbms/libdbms.o ../rdfstore_flat_store.o ../rdfstore_kernel.o ../rdfstore_bits.o ../rdfstore_utf8.o ../rdfstore_xsd.o ../rdfstore_digest.o ../rdfstore_ap_sha1.o ../rdfstore_compress.o ../rdfstore_log.o ../rdfstore_iterator.o  ../rdfstore_serializer.o ../sflcomp.o ../my_compress.o ../fraenkel_compress.o ../backend_bdb_store.o ../backend_dbms_store.o ../backend_caching_store.o


all:	mytest mytest1 myingest

test:	all
	./mytest || exit 1
	./mytest1 || exit 1
	./myingest test.triples || exit 1

clean:
	rm -f mytest mytest1 myingest myingest.core mytest.core mytest1.core mytest.gmon mytest1.gmon

mytest: Makefile mytest.c
	$(CC) $(CFLAGS) $(INCLUDES) -I ../dbms/include -I ../dbms/client $(DEFINES) $(LIBS_DIR) $(OBJS)  -o mytest mytest.c

mytest1: Makefile mytest1.c
	$(CC) $(CFLAGS) $(INCLUDES) -I ../dbms/include -I ../dbms/client $(DEFINES) $(LIBS_DIR) $(OBJS)  -o mytest1 mytest1.c

myingest: Makefile myingest.c
	$(CC) $(CFLAGS) $(INCLUDES) -I ../dbms/include -I ../dbms/client $(DEFINES) $(LIBS_DIR) $(OBJS)  -o myingest myingest.c

