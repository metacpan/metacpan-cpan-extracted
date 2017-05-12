# $Id: Makefile,v 1.6 2007-08-31 11:58:17 mike Exp $

STUFF = simple2zoom.rng simple2zoom.dtd simple2zoom.xsd

lint: lint-rng lint-schema lint-dtd 

lint-rng: test.xml simple2zoom.rng
	xmllint --relaxng simple2zoom.rng --noout test.xml

lint-dtd: test.xml simple2zoom.dtd
	xmllint --dtdvalid simple2zoom.dtd --noout test.xml

lint-schema: test.xml simple2zoom.xsd
	xmllint --schema simple2zoom.xsd --noout test.xml

all: $(STUFF)

%.rng: %.rnc
	rm -f $@
	trang $? $@
	chmod 444 $@

%.dtd: %.rnc
	rm -f $@
	trang $< $@
	chmod 444 $@

%.xsd: %.rnc
	rm -f $@
	trang $< $@
	chmod 444 $@

clean:
	rm -f $(STUFF)

