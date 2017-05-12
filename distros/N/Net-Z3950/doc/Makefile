# $Header: /home/cvsroot/NetZ3950/doc/Makefile,v 1.6 2004/11/22 22:59:58 mike Exp $

MODULES = Z3950 Z3950/Tutorial Z3950/Manager Z3950/Connection Z3950/APDU \
	Z3950/ResultSet Z3950/Record
PERL = $(MODULES:%=../%.pm)
HTML = $(MODULES:%=%.html)
JUNK = pod2html-dircache pod2html-itemcache \
       pod2htmd.x~~ pod2htmi.x~~ \
       pod2htmd.tmp pod2htmi.tmp

all: Z3950 Z3950/style.css $(HTML)

Z3950:
	mkdir Z3950

Z3950/style.css: style.css
	rm -f $@; cp $? $@

%.html: ../%.pm
	./htmlify < $? > $@

### Why do we need this rule?  Isn't is a special case of the last one?
Z3950/%.html: ../Z3950/%.pm
	./htmlify < $? > $@

clean:
	rm -f $(HTML) Z3950/style.css $(JUNK)
	rmdir Z3950

distclean: clean
