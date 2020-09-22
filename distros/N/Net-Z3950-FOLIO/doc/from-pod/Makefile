# This Makefile regenerates the Markdown documentation from the POD
# sources. It should be run after changing those documents and before
# pushing the relevant commits, so that the Markdown form of the
# documentation, which is directly viewable in GitHub, is in sync.
#
# You will need to install the Pod::Markdown module before running
# this.

FILES=z2folio.md Net-Z3950-FOLIO.md Net-Z3950-FOLIO-Config.md

all: $(FILES)

z2folio.md: ../../bin/z2folio
	rm -f $@
	pod2markdown $? > $@
	chmod ugo-w $@

Net-Z3950-FOLIO.md: ../../lib/Net/Z3950/FOLIO.pm
	rm -f $@
	pod2markdown $? > $@
	chmod ugo-w $@

Net-Z3950-FOLIO-Config.md: ../../lib/Net/Z3950/FOLIO/Config.pod
	rm -f $@
	pod2markdown $? > $@
	chmod ugo-w $@

clean:
	rm -f $(FILES)

