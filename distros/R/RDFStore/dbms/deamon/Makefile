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
INSTDIR=/RDFStore

include ../arch.conf

SRCS = deamon.c mymalloc.c handler.c main.c children.c loop.c pathmake.c conf.c
OBJS = ${SRCS:c=o}
INCL = dbmsd.h deamon.h handler.h mymalloc.h pathmake.h conf.h

INSTALL = install -c 

CFLAGS += -DDIR_PREFIX="\"${INSTDIR}\"" -DCONF_FILE="\"${INSTDIR}/etc/dbms.conf\"" 

all: dbmscheckconf dbmsd $(INCL) ../include/dbms.h Makefile man

test: dbmsd testconf dbms-allow-all.conf   
	@rm -f ${TESTDIR}/*/*db
	@rm -f *db
	-@../utils/stop_dbserver ${PIDFILE} 2> /dev/null 1>&2

	@mkdir -p ${TESTDIR}
	@echo -n Starting DBMS deamon.....
	LD_LIBRARY_PATH=$(BDB_LD_LIBS_DIR) ./dbmsd -U -d ${TESTDIR} -P ${PIDFILE} -c dbms-allow-all.conf &
	@echo DONE

	@(cd ../client; make test)

	@echo -n Stopping DBMS deamon.....
	@../utils/stop_dbserver ${PIDFILE} 2> /dev/null 1>&2
	@echo DONE

	@rm -f *.gmon bb.*
	@rm -f ${TESTDIR}/*/*db
	@rm -f *db

.c.o:	Makefile
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) -c -o $@ $<

version: 
	./version.pl > version.c
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) -c -o version.o version.c

${OBJS}: Makefile *.h

dbmsd:	${OBJS} version
	${CC} $(CFLAGS) ${LFLAGS} $(LIBS_DIR) -o $@ ${OBJS} version.o ${LIBS}

clean:
	rm -f version.c dbmsd dbmsd.8.gz
	rm -f *.o *.gmon bb.* core.* *.core *.db dbmscheckconf dbmscheckconf.8.gz

man: dbmsd.8 dbmscheckconf.8
	cat dbmsd.8 | gzip > dbmsd.8.gz
	cat dbmscheckconf.8 | gzip > dbmscheckconf.8.gz

install: dbmsd man dbmscheckconf dbms.conf
	mkdir -p $(INSTDIR)/bin $(INSTDIR)/rc $(INSTDIR)/man/man8 $(INSTDIR)/dbms  $(INSTDIR)/etc $(INSTDIR)/run $(INSTDIR)/logs
	-chmod a+w $(INSTDIR)/dbms
	-chmod a+w $(INSTDIR)/logs
	-chmod a+w $(INSTDIR)/run
	-cp $(INSTDIR)/etc/dbms.conf $(INSTDIR)/etc/dbms.conf.ORIG
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) dbms-allow-all.conf $(INSTDIR)/etc/dbms.conf
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) dbms.conf $(INSTDIR)/etc/dbms.conf-sample
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) dbmsd $(INSTDIR)/bin
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) dbmscheckconf $(INSTDIR)/bin
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) ../utils/dbmsd.sh $(INSTDIR)/rc
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) ../utils/start_dbserver $(INSTDIR)/rc
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) ../utils/stop_dbserver $(INSTDIR)/rc
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) ../utils/dbms_mirror.pl $(INSTDIR)/bin
	$(INSTALL) -m 0644 -o $(UID) -g $(GID) dbmsd.8.gz $(INSTDIR)/man/man8
	$(INSTALL) -m 0644 -o $(UID) -g $(GID) dbmscheckconf.8.gz $(INSTDIR)/man/man8

	@echo "Remember to set your local LD_LIBRARY_PATH to point to the right Berkeley DB libraries directory if not found by ld program"

depend:
	makedepend $(INCLUDES) $(DEFINES) $(SRCS)

distclean: clean
	rm -f *% 

dbmscheckconf: conf.c $(INCL) 
	 $(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) -D__TESTING__CONF__ -o $@ conf.c $(LIBS)

testconf: dbmscheckconf
	LD_LIBRARY_PATH=$(BDB_LD_LIBS_DIR) ./dbmscheckconf ./dbms.conf `cat test-xs.conf`

lint: 
	$(LINT) $(LINTFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) ${SRCS}
