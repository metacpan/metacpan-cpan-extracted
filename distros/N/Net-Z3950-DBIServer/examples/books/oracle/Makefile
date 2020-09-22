# $Id: Makefile,v 1.2 2008-05-16 15:54:01 mike Exp $

TABLES = country author book
FILES = $(TABLES:%=../%.data)

insert.sql: ../postgres/make-insert.pl $(FILES)
	$< $(TABLES) > $@

clean:
	rm -f insert.sql
