# $Id: Makefile,v 1.2 2004/12/22 13:32:39 mike Exp $

MARC = trunc.marc boolean.marc

default: $(MARC)

%.marc: %.hrm hrm2marc.pl
	./hrm2marc.pl $< > $@

clean:
	rm -f $(MARC)

