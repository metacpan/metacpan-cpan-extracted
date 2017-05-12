# Makefile for libqstruct

########################################################################
# Configuration.
########################################################################

CC     = gcc
W      = -W -Wall -Wbad-function-cast -Wextra -Wformat=2 -Wpointer-arith -Wfloat-equal -Wdeclaration-after-statement -Wshadow -Wunsafe-loop-optimizations -Wbad-function-cast -Wcast-qual -Wcast-align -Waggregate-return -Wmissing-field-initializers -Wredundant-decls -Woverlength-strings -Winline -Wdisabled-optimization -Wstack-protector
OPT    = -O2 -g
CFLAGS = $(OPT) $(W) -fPIC $(XCFLAGS)
LDLIBS = $(XLDLIBS)
SOLIBS =
prefix = /usr/local

########################################################################

INSTALLEDHDRS = qstruct/utils.h qstruct/compiler.h qstruct/loader.h qstruct/builder.h
INSTALLEDLIBS = libqstruct.a libqstruct.so
OBJS = parser.o compiler.o

all: $(INSTALLEDLIBS)

install: $(INSTALLEDLIBS) $(INSTALLEDHDRS)
	for f in $(INSTALLEDLIBS); do cp $$f $(DESTDIR)$(prefix)/lib; done
	mkdir $(DESTDIR)$(prefix)/include/qstruct/
	for f in $(INSTALLEDHDRS); do cp $$f $(DESTDIR)$(prefix)/include/qstruct/; done

uninstall:
	rm $(DESTDIR)$(prefix)/lib/libqstruct.*
	rm -f $(DESTDIR)$(prefix)/include/qstruct/*.h
	rmdir $(DESTDIR)$(prefix)/include/qstruct/

clean:
	rm -rf *.[ao] *.so parser.c

libqstruct.a: $(OBJS)
	ar rs $@ $(OBJS)

libqstruct.so: $(OBJS)
	$(CC) $(LDFLAGS) -shared -o $@ $(OBJS) $(SOLIBS)

parser.o: parser.c qstruct/compiler.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -c parser.c

parser.c: parser.rl Makefile
	ragel -T0 parser.rl

%: %.o Makefile
	$(CC) $(CFLAGS) $(LDFLAGS) $^ $(LDLIBS) -o $@

%.o: %.c $(INSTALLEDHDRS) Makefile
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $<
