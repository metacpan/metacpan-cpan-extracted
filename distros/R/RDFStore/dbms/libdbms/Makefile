# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *     		   Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *

# external dbmsd to use for the make test functionality.
#
TMPDIR=/tmp
DBMSD=../deamon/dbmsd
PIDFILE=${TMPDIR}/dbmsd.test.pid

include ../arch.conf
SRCS = libdbms.c
OBJS = ${SRCS:c=o}
INCL = 

INSTALL = install -c 

all:	dump libdbms.a $(INCL) ../include/dbms.h Makefile

dump:	dump.o libdbms.a $(INCL) ../include/dbms.h Makefile
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) $(LIBS) -o dump dump.o libdbms.a


test:	test.o all ../deamon/dbmsd dbms-test.conf
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) $(LIBS) -o test test.o libdbms.a
	${DBMSD} -U -d ${TMPDIR} -c ./dbms-test.conf -P ${PIDFILE}
	- rm ${TMPDIR}/te/test.db
	-./test
	kill `cat ${PIDFILE}`
	rm ${PIDFILE}

${OBJS}:	Makefile

.c.o:	Makefile
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) -c -o $@ $<

libdbms.a: ${OBJS}
	$(AR) cr $@ ${OBJS}
	$(RANLIB) $@
	
clean:
	rm -f *.o *.gmon bb.* core.* *.core *.db *.a *.dylib

man: libdbms.3
	cat libdbms.3 | gzip > libdbms.3.gz

install: man libdbms.a
	-mkdir -p $(INSTDIR)/lib $(INSTDIR)/man/man3 $(INSTDIR)/include
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) libdbms.a $(INSTDIR)/lib
	$(INSTALL) -m 0644 -o $(UID) -g $(GID) libdbms.3.gz $(INSTDIR)/man/man3
	$(INSTALL) -m 0444 -o $(UID) -g $(GID) ../include/dbms.h  $(INSTDIR)/include
	$(INSTALL) -m 0444 -o $(UID) -g $(GID) ../include/dbms_comms.h  $(INSTDIR)/include
	$(INSTALL) -m 0444 -o $(UID) -g $(GID) ../include/dbms_compat.h  $(INSTDIR)/include

depend:
	makedepend $(INCLUDES) $(DEFINES) $(SRCS)

distclean: clean
	rm -f *% 

lint: 
	$(LINT) $(LINTFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) ${SRCS}
