# $Id: Makefile,v 1.1 2002-11-28 08:42:07 mike Exp $
#
# This Makefile is for regression-testing the configuration-file
# compiler only.  There's no need for anyone except me ever to use it.

NZD = ../examples/books/books.nzd

test:
	(cd .. && make)
	./render-config $(NZD) | diff reference -

reference: render-config $(NZD) Config.pm
	(cd .. && make)
	./render-config $(NZD) > reference
