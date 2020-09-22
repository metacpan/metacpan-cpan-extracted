# $Header: /home/mike/cvs/mike/zSQLgate/doc/Makefile,v 1.8 2005-02-18 13:41:28 mike Exp $

MODULES = DBIServer/LICENCE DBIServer/Intro DBIServer/Install \
	DBIServer/Tutorial DBIServer/Run DBIServer/Spec DBIServer \
	DBIServer/Config DBIServer/ResultSet DBIServer/GRS1 \
	DBIServer/XML DBIServer/Exception DBIServer/MARC
PERL = $(MODULES:%=../%.pm)
DIRS = Net Net/Z3950 Net/Z3950/DBIServer
CSS = Net/Z3950/style.css Net/Z3950/DBIServer/style.css 
HTML = zSQLgate.html $(MODULES:%=Net/Z3950/%.html)
JUNK = pod2html-dircache pod2html-itemcache \
	pod2htmd.x~~ pod2htmi.x~~ \
	pod2htmd.tmp pod2htmi.tmp

all: $(DIRS) $(CSS) $(HTML)

Net Net/Z3950 Net/Z3950/DBIServer:
	mkdir $@

$(CSS): style.css
	rm -f $@; cp $? $@

Net/Z3950/%.html: ../lib/Net/Z3950/%.pm
	./htmlify < $? > $@

### Why do we need this rule?  Isn't is a special case of the last one?
Net/Z3950/DBIServer/%.html: ../lib/Net/Z3950/DBIServer/%.pm
	./htmlify < $? > $@

zSQLgate.html: ../bin/zSQLgate
	./htmlify < $? > $@

clean:
	rm -f $(CSS) $(HTML) $(JUNK)
	rmdir Net/Z3950/DBIServer Net/Z3950 Net 2>/dev/null ||:
