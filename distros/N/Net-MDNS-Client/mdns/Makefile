all: mquery mhttp libmdns_server.so libmdns_client.so libmdns_client.a libmdns_server.a tests

install: all
	cp libmdns_client.so libmdns_server.so /usr/lib  || true
	ln -s /usr/lib/libmdns_client.so /usr/lib/libmdns_client.so.0  || true
	ln -s /usr/lib/libmdns_client.so /usr/lib/libmdns_client.so.0.0.0  || true
	ln -s /usr/lib/libmdns_server.so /usr/lib/libmdns_server.so.0  || true
	ln -s /usr/lib/libmdns_server.so /usr/lib/libmdns_server.so.0.0.0  || true

mhttp: mhttp.c
	gcc -g -o mhttp mhttp.c mdnsd.c 1035.c sdtxt.c xht.c

mquery: mquery.c
	gcc -g -o mquery mquery.c mdnsd.c 1035.c

libmdns_server.so: mdns_server.h mdns_server.c
	gcc -fPIC -Wall -g -c mdns_server.c mdnsd.c 1035.c sdtxt.c xht.c 
	gcc -g -fPIC -shared -Wl,-soname,libmdns_server.so.0 -o libmdns_server.so.0.0 -lc mdns_server.o mdnsd.o 1035.o sdtxt.o xht.o 
	ln -sf libmdns_server.so.0.0 libmdns_server.so
	ln -sf libmdns_server.so.0.0 libmdns_server.so.0

libmdns_server.a: libmdns_server.so
	ar -rcs libmdns_server.a libmdns_server.so

libmdns_client.so: mdns_client.h mdns_client.c
	gcc -fPIC -Wall -g -c  mdnsd.c 1035.c sdtxt.c xht.c mdns_client.c
	gcc -g -fPIC -shared -Wl,-soname,libmdns_client.so.0 -o libmdns_client.so.0.0 -lc mdns_client.o 1035.o sdtxt.o xht.o mdnsd.o
	ln -sf libmdns_client.so.0.0 libmdns_client.so
	ln -sf libmdns_client.so.0.0 libmdns_client.so.0

libmdns_client.a: libmdns_client.so
	ar -rcs libmdns_client.a libmdns_client.so

tests: test_client test_server

test_client: test_client.c
#	gcc -ggdb test_client.c mdns_client.c mdnsd.c xht.c 1035.c -o test_client
	gcc -ggdb test_client.c -L./ -lmdns_client -o test_client

test_server: test_server.c
	gcc -ggdb test_server.c sdtxt.c mdns_server.c mdnsd.c xht.c 1035.c -o test_server

clean:
	rm -f mquery mhttp
	rm -f *~
	rm -f *.o
	rm -f *.a
	rm -f *.so
	rm -f *.so.0
	rm -f *.so.0.0
	rm test_client
	rm test_server
