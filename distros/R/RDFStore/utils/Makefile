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

OBJS = ../dbms/libdbms/libdbms.o ../rdfstore_flat_store.o ../rdfstore_kernel.o ../rdfstore_bits.o ../rdfstore_utf8.o ../rdfstore_xsd.o ../rdfstore_digest.o ../rdfstore_ap_sha1.o ../rdfstore_compress.o ../rdfstore_log.o ../rdfstore_serializer.o ../rdfstore_iterator.o ../sflcomp.o ../my_compress.o ../fraenkel_compress.o ../backend_bdb_store.o ../backend_dbms_store.o ../backend_caching_store.o

all:	db_stats

clean:
	rm -f db_stats

db_stats: db_stats.c Makefile
	$(CC) $(CFLAGS) $(INCLUDES) -I ../dbms/include -I ../dbms/client $(DEFINES) $(LIBS_DIR) $(OBJS)  -o db_stats db_stats.c