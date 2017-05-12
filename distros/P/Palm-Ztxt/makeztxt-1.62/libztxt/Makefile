###############################################################################
# Makefile for libztxt
#
# $Id: Makefile 395 2007-01-13 10:32:34Z foxamemnon $
###############################################################################

VERSION	= 2.01

LIBNAME	= libztxt.a

INCLUDE	= -I../../common -I..

CFLAGS	+= $(INCLUDE)

SRC	= ztxt_add_regex.c ztxt_generate_db.c ztxt_list_bookmarks.c \
	  ztxt_set.c ztxt_free.c ztxt_init.c ztxt_process.c ztxt_info.c \
	  ztxt_add_bookmark.c ztxt_util.c ztxt_disect.c ztxt_add_annotation.c \
	  ztxt_get.c ztxt_crc32.c

OBJS	= $(SRC:.c=.o)


ifeq ($(PACK),1)
	CFLAGS += -fpack-struct
endif

ifeq ($(USEPOSIX),1)
	CFLAGS += -DPOSIX_REGEX=1
endif


all: libztxt

.c.o:
	$(CC) $(CFLAGS) -c $<

libztxt: $(LIBNAME)


$(LIBNAME): $(OBJS)
	ar rs $(LIBNAME) $(OBJS)
	ranlib $(LIBNAME)


build.h: buildcounter
	echo "#ifndef LIBZTXT_BUILD_H" > build.h
	echo "#define LIBZTXT_BUILD_H 1" >> build.h
	echo "#define LIBZTXT_VERSION \"$(VERSION)\"" >> build.h
	echo "#define LIBZTXT_BUILDNUM `cat buildcounter`" >> build.h
	echo "#endif" >> build.h


# Cleaning and Makefile maintainence
clean:
	-rm -f *.o *~ *.bak $(LIBNAME) build.h

depends:
	makedepend -Y. $(SRC) >/dev/null 2>&1


# DO NOT DELETE

ztxt_add_regex.o: ztxt.h databaseHdrs.h
ztxt_generate_db.o: ztxt.h databaseHdrs.h build.h
ztxt_list_bookmarks.o: ztxt.h databaseHdrs.h
ztxt_set.o: ztxt.h databaseHdrs.h
ztxt_free.o: ztxt.h databaseHdrs.h
ztxt_init.o: ztxt.h databaseHdrs.h
ztxt_process.o: ztxt.h databaseHdrs.h
ztxt_info.o: build.h
ztxt_add_bookmark.o: ztxt.h databaseHdrs.h
ztxt_util.o: ztxt.h databaseHdrs.h
ztxt_disect.o: ztxt.h databaseHdrs.h
ztxt_add_annotation.o: ztxt.h databaseHdrs.h
ztxt_get.o: ztxt.h databaseHdrs.h
ztxt_crc32.o: ztxt.h databaseHdrs.h
