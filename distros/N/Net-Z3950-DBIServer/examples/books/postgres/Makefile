# $Id: Makefile,v 1.2 2008-05-16 15:54:20 mike Exp $

TABLES = country author book
FILES = $(TABLES:%=../%.data)

insert.sql: make-insert.pl $(FILES)
	./make-insert.pl $(TABLES) > $@

clean:
	rm -f insert.sql
