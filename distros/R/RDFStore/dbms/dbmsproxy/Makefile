# *
# *     Copyright (c) 2005 Asemantics S.R.L., All Rights Reserved.
# *

include ../arch.conf

CFLAGS+=-Wall -ggdb

# CFLAGS+= -DLOCALTEST

SRCS = dbmsproxy.c
OBJS = ${SRCS:c=o}
INCL = dbmsproxy.h

INSTALL = install -c 

all: dbmsget dbmsproxy

${OBJS}: Makefile *.h

.c.o: Makefile
	$(CC) $(CFLAGS) $(INCLUDES) $(DEFINES) $(LIBS_DIR) -c -o $@ $<

dbmsget: dbmsget.o
	${CC} $(CFLAGS) ${LFLAGS} $(LIBS_DIR) -o $@ $? ${LIBS}

dbmsproxy: dbmsproxy.o
	${CC} $(CFLAGS) ${LFLAGS} $(LIBS_DIR) -o $@ $? ${LIBS} -ldbms

clean:
	rm -f *.o ktrace.* *core dbmsproxy dbmsget

install: dbmsproxy dbmsget
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) dbmsproxy $(INSTDIR)/bin
	$(INSTALL) -m 0555 -o $(UID) -g $(GID) dbmsget $(INSTDIR)/bin
	$(INSTALL) -m 0444 -o $(UID) -g $(GID) dbmsproxy.h $(INSTDIR)/include

depend:
	makedepend $(INCLUDES) $(DEFINES) $(SRCS)

distclean: clean
	rm -f *% 
