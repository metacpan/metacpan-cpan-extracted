###############################################################################
# Makefile for makeztxt
#
# $Id: Makefile 412 2007-06-21 06:57:30Z foxamemnon $
###############################################################################

VERSION	= 1.62

LIBS	= -lztxt
INCLUDE	= -I../common -I.

CC	= gcc
CFLAGS	= -Wall -O2 -pipe $(INCLUDE)
# GNU make is mandatory
#MAKE	= make


######################################
#####    Compilation  Options    #####
#####   Change for your system   #####
######################################

# Turns on -fpack-struct which some systems need to properly handle the
# packed structs in Palm DB headers.
# If you're compiling on a Sun (with gcc), you'll need this.
#PACK = 1

# By default, libztxt will use GNU regex.  This is good because they are
# more featureful and faster (on large strings) than POSIX regex.
# But... maybe you don't have GNU regex.
# In particular, if compiling with Cygwin, you need this.
#USEPOSIX = 1

# DOS, in all its infinite wisdom, decided long ago to differentiate between
# text files and binary files.  Text files get their \n converted to \r\n and
# vice-versa.  This is bad and stupid.  DOS is bad and stupid.  Uncomment
# this line if compiling for DOS (or any platform which makes the above
# distinction).  Specifically, this makes files opens used the O_BINARY flag.
#HAVEBINARYFLAG = 1

# To avoid extra DLL dependencies, statically link against libz.a.  This can
# be desirable with the Cygwin binary.
#STATICLIBS = 1

# If you're on a system that does not have getopt.h or does not have the
# getopt_long() function, comment this out.  Regular getopt() will be used.
LONG_OPTS = 1

# Enable debugging symbols and any debugging code
#DEBUG = 1


#####################################
#####  End user config section  #####
#####################################



SRC	= makeztxt.c
OBJS	= $(SRC:.c=.o)

DISTFILES  = $(SRC) ../common/weasel_common.h \
	     Makefile ChangeLog ../COPYING README .makeztxtrc

BINFILES   = makeztxt ChangeLog ../COPYING README .makeztxtrc


ifeq ($(PACK),1)
	CFLAGS += -fpack-struct
endif

ifeq ($(USEPOSIX),1)
	CFLAGS += -DPOSIX_REGEX=1
endif

ifneq ($(HAVEBINARYFLAG),1)
	CFLAGS += -DO_BINARY=0
endif

ifeq ($(STATICLIBS),1)
	LIBS += /lib/libz.a
else
	LIBS += -lz
endif

ifeq ($(LONG_OPTS),1)
	CFLAGS += -DLONG_OPTS=1
endif

ifeq ($(DEBUG),1)
	CFLAGS += -g -DDEBUG=1
endif




all: makeztxt

.c.o:
	$(CC) $(CFLAGS) -c $<

makeztxt: $(OBJS) libztxt/libztxt.a libztxt/ztxt.h
	$(CC) -Llibztxt -o makeztxt $(OBJS) $(LIBS)

libztxt/libztxt.a::
	$(MAKE) -C libztxt CC=$(CC) USEPOSIX=$(USEPOSIX) PACK=$(PACK) DEBUG=$(DEBUG) all


# Cleaning and Makefile maintainence
clean:
	$(MAKE) -C libztxt clean
	-rm -f *.o *~

distclean: clean
	-rm -f makeztxt

depends:
	makedepend -Y. $(INCLUDE) $(SRC)



# The GPL makes a good test database
gpl.pdb:
	./makeztxt -l -t "GNU General Public License" -r Preamble -r "TERMS AND CONDITIONS FOR COPYING" -r "  NO WARRANTY" -r "END OF TERMS AND CONDITIONS" ../COPYING
	mv COPYING.pdb ../pdb/GPL.pdb



# This makes it much easier for me to make distributions
alldist: dist dist-zip dist-bin dist-bin-zip

dist:
	mkdir makeztxt-$(VERSION)
	mkdir makeztxt-$(VERSION)/libztxt
	cp $(DISTFILES) makeztxt-$(VERSION)
	cp libztxt/*.c makeztxt-$(VERSION)/libztxt
	cp libztxt/*.h makeztxt-$(VERSION)/libztxt
	cp libztxt/Makefile makeztxt-$(VERSION)/libztxt
	cp libztxt/buildcounter makeztxt-$(VERSION)/libztxt
	cp libztxt/inc_bcounter.sh makeztxt-$(VERSION)/libztxt
	tar czf makeztxt-$(VERSION)-src.tar.gz makeztxt-$(VERSION)
	rm -rf makeztxt-$(VERSION)

dist-zip:
	mkdir makeztxt-$(VERSION)
	mkdir makeztxt-$(VERSION)/libztxt
	cp $(DISTFILES) makeztxt-$(VERSION)
	cp libztxt/*.c makeztxt-$(VERSION)/libztxt
	cp libztxt/*.h makeztxt-$(VERSION)/libztxt
	cp libztxt/Makefile makeztxt-$(VERSION)/libztxt
	cp libztxt/buildcounter makeztxt-$(VERSION)/libztxt
	cp libztxt/inc_bcounter.sh makeztxt-$(VERSION)/libztxt
	-cd makeztxt-$(VERSION) ; flip -m *
	zip -9r makeztxt-$(VERSION)-src.zip makeztxt-$(VERSION)
	rm -rf makeztxt-$(VERSION)

dist-bin: makeztxt
	mkdir makeztxt-$(VERSION)
	cp $(BINFILES) makeztxt-$(VERSION)
	tar czf makeztxt-$(VERSION).i386.tar.gz makeztxt-$(VERSION)
	rm -rf makeztxt-$(VERSION)

dist-bin-zip: makeztxt
	mkdir makeztxt-$(VERSION)
	cp $(BINFILES) makeztxt-$(VERSION)
	-cd makeztxt-$(VERSION) ; flip -m *
	zip -9r makeztxt-$(VERSION).i386.zip makeztxt-$(VERSION)
	rm -rf makeztxt-$(VERSION)

