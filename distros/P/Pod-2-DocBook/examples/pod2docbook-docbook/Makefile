BOOKNAME=Pod-2-DocBook
#DRAFT=--stringparam draft.watermark.image images/draft.png

XML=*.xml chapters/*.xml
PODXML=chapters/pod/Pod-2-DocBook.xml chapters/pod/pod2docbook.xml
IMAGES=images/*.png
XINCLUDES=chapters/examples/*
SOURCES=$(XML) $(PODXML) $(IMAGES) $(XINCLUDES) entities.mod Makefile
POD2DOCBOOK=pod2docbook
PODROOT=code


FOP=fop

## Needed by xmllint and xsltproc in order to find the catalog
export XML_CATALOG_FILES=/etc/xml/catalog catalog.xml


all: $(BOOKNAME).html $(BOOKNAME).pdf


.validated: $(SOURCES)
	xmllint --xinclude --postvalid --noout book.xml
	touch .validated


$(BOOKNAME).html: .validated $(SOURCES)
	xsltproc --xinclude $(DRAFT) \
	--stringparam draft.mode no \
	--stringparam admon.graphics 1 \
	--stringparam admon.graphics.extension .png \
	--stringparam html.stylesheet docbook.css \
	--output $@ html-stylesheet.xsl book.xml


$(BOOKNAME).pdf: book.fo
	$(FOP) -fo $< -pdf $@ -d


book.fo: .validated $(SOURCES) Makefile
	xsltproc --xinclude $(DRAFT) \
	--stringparam paper.type A4 \
	--stringparam draft.mode no \
	--stringparam fop.extensions 1 \
	--stringparam admon.graphics 1 \
	--stringparam admon.graphics.extension .png \
	--stringparam generate.toc "book toc,title" \
	--output $@ fo-stylesheet.xsl book.xml

# pod2docbook transformation
chapters/pod/Pod-2-DocBook.xml: $(PODROOT)/DocBook.pm
	$(POD2DOCBOOK) --title='Pod-2-DocBook POD' --doctype=section  $< $@	
chapters/pod/pod2docbook.xml: $(PODROOT)/pod2docbook
	$(POD2DOCBOOK) --title='pod2docbook script' --doctype=section  $< $@	


.PHONY: clean
clean:
	rm -f book.fo
	rm -f $(BOOKNAME).pdf
	rm -f $(BOOKNAME).html
	find $(PODROOT) -type f -exec touch {} \;
	rm -f .validated
