### Makefile --- 

## Author: pajas@ufal.ms.mff.cuni.cz
## Version: $Id: Makefile,v 0.0 2008/09/27 07:08:36 pajas Exp $
## Keywords: 
## X-URL: 

XSL=html.xsl
FOXSL=print.xsl

XSL_ORIG=http://docbook.sourceforge.net/release/xsl/current/html/docbook.xsl
FOXSL_ORIG=http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl

.PHONY: clean rails all html tex installhtml install cleanall cleanhtml

all: rails html

html: pmltq_doc.html

tutweb: pmltq_tutorial_web_client.html

print: pmltq_doc.fo

htmltex: pmltq_doc.html tex

tex: tex-math-equations.tex
	./tex2bitmap.sh tex-math-equations.tex

rails: pmltq_doc.xml mk_rail.sh mk_rails.xsh
	./mk_rails.xsh pmltq_doc.xml

pmltq_doc.html: pmltq_doc.xml
	xsltproc --xinclude \
           --param ignore.image.scaling 1 \
	   --stringparam use.role.for.mediaobject 1 \
           --stringparam preferred.mediaobjectrole html \
           --stringparam html.stylesheet blue.css \
           --stringparam tex.math.in.alt latex \
        -o pmltq_doc.html $(XSL) pmltq_doc.xml 

pmltq_tutorial_web_client.html: pmltq_tutorial_web_client.xml
	xsltproc --xinclude \
	   --stringparam use.role.for.mediaobject 1 \
           --stringparam preferred.mediaobjectrole html \
           --stringparam html.stylesheet blue.css \
           --stringparam tex.math.in.alt latex \
        -o pmltq_tutorial_web_client.html $(XSL) pmltq_tutorial_web_client.xml 

pmltq_doc.fo: pmltq_doc.xml
	xsltproc --xinclude \
	   --stringparam use.role.for.mediaobject 1 \
           --stringparam tex.math.in.alt latex \
	-o pmltqdoc.fo $(FOXSL) pmltq_doc.xml 
	xep pmltqdoc.fo # pdfxmltex pmltqdoc.fo

installhtml:
	scp pmltq_doc.html ufal:/home/pajas/WWW/pmltq/doc

install:
	scp pmltq_doc.html rail_*.png ufal:/home/pajas/WWW/pmltq/doc

cleanall: clean cleanhtml
	rm pmltq_doc.html rail_*.pdf rail_*.png

cleanhtml: clean
	rm pmltq_doc.html

clean:
	rm -f rail_*.log  rail_*.aux rail_*.tex rail_*.rao rail_*.rai *.out *~

### Makefile ends here
