CFLAGS=-Wall -fPIC -g
# CFLAGS=-Wall -DYY_DEBUG=1 -fPIC -g
# -std=c89
CC=cc

all: pvip

pvip: libpvip.a src/main.c src/commander.o
	gcc $(CFLAGS) -o pvip src/commander.o src/main.c libpvip.a

libpvip.a: src/gen.pvip.y.o src/pvip.h src/pvip_node.o src/gen.node.o src/pvip_string.o
	ar rsv libpvip.a src/gen.pvip.y.o src/pvip_node.o src/gen.node.o src/pvip_string.o

test: pvip t/c_level.t
	prove -lr t

.c.o: src/pvip.h
	$(CC) $(CFLAGS) -c -o $@ $<

t/c_level.t: src/c_level_test.o libpvip.a
	$(CC) $(CFLAGS) -o t/c_level.t src/c_level_test.o libpvip.a

src/main.o: src/pvip.h
src/pvip_node.o: src/pvip.h

src/gen.node.c: build/node.pl src/pvip.h
	perl build/node.pl

3rd/greg/greg:
	cd 3rd/greg/ && $(CC) -g -o greg greg.c compile.c tree.c

src/gen.pvip.y.c: src/pvip.y src/pvip.h src/gen.node.c 3rd/greg/greg
	./3rd/greg/greg -o src/gen.pvip.y.c src/pvip.y

clean:
	rm -f src/*.o src/gen.* pvip libpvip.a

.PHONY: all test

