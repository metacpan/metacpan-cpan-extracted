# Makefile for Documentation
# //////////////////////////

PERL=/usr/bin/perl


PPDOC = ./PPDOC
GETTIN_STARTED = $(PPDOC)/Getting-Started/slide0000.htm
FAQ_PARSER  = $(PPDOC)/FAQ-Parser/slide0000.htm
FAQ_PP2HTML = $(PPDOC)/FAQ-pp2html/slide0000.htm
REF_PP2HTML = $(PPDOC)/REF-pp2html/slide0000.htm
WRITING_CONVERTERS = $(PPDOC)/Writing-Converters/slide0000.htm

PP2HTML    = $(PERL) -I../lib ../pp2html

all:  $(FAQ_PP2HTML) $(REF_PP2HTML) $(FAQ_PARSER) $(GETTIN_STARTED) $(WRITING_CONVERTERS)

ref_pp2html: $(REF_PP2HTML) 
faq_parser: $(FAQ_PARSER)

$(GETTIN_STARTED): getting-started.pp getting-started.cfg
	$(PP2HTML) @getting-started.cfg getting-started.pp


$(FAQ_PP2HTML): pp2html-faq.pp pp2html-faq.cfg parser-tags.pp tagdoc-supported.pp
	$(PP2HTML) @pp2html-faq.cfg pp2html-faq.pp

$(FAQ_PARSER): parser-faq.pp parser-faq.cfg
	$(PP2HTML) @parser-faq.cfg parser-faq.pp

$(REF_PP2HTML): pp2html-ref.pp pp2html-ref.cfg pp2html-ref-options.pp doc-functions.pp parser-paragraphs.pp \
         parser-active-contents.pp
	$(PP2HTML) @pp2html-ref.cfg pp2html-ref.pp

$(WRITING_CONVERTERS): writing-converters.pp writing-converters.cfg
	$(PP2HTML) @writing-converters.cfg writing-converters.pp


pp2html-ref-options.pp: ../pp2html
	$(PERL) ./extract_pod.pl ../pp2html > pp2html-ref-options.pp

depend:
	gen_depends > .depends

include .depends
