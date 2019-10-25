#  Copyright (C) <%= ${year} %> <%= ${fullName} %>

AUTOMAKE_OPTIONS =  foreign

SUBDIRS = bin lib thirdparty etc <%= ${package} eq 'callbackery' ? 'frontend' : '' %>

BIN = bin/$(MJ_SCRIPT).pl

PUB := $(shell find public -type d -name ".??*" -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -type f -print )
TEMPL := $(shell test -d templates && find templates -type f -name "*.ep")
SHARE := $(shell test -d share && find share -type d -name ".??*" -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -type f -print)

PERLTESTS := $(shell find t -name "*.t")
PM := $(shell find lib -name "*.pm")

EXTRA_DIST = VERSION PERL_MODULES COPYRIGHT LICENSE CHANGES AUTHORS bootstrap $(PUB) $(wildcard t/*.t) $(BIN) $(POD) $(TEMPL) $(PERLTESTS) $(SHARE)

YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)

datadir = $(prefix)
nobase_data_DATA = $(PUB) $(TEMPL) $(SHARE)

README.md COPYRIGHT: VERSION
	$(PERL) -i -p -e 's/(#VERSION#|\d+\.\d+\.\d+[^.\s]*)/$(PACKAGE_VERSION)/g;s/(#YEAR#|20[1-9]\d)/$(YEAR)/g;s/(#DATE#|20[1-9]\d-[01]\d-[0-3]\d)/$(DATE)/g;' $@

dist-hook:
% if ( ${package} eq 'callbackery' ) { 
	$(PERL) -i -p -e 's/#VERSION#/$(PACKAGE_VERSION)/g;s/#YEAR#/$(YEAR)/g;s/#DATE#/$(DATE)/g;' $(distdir)/public/$(QX_CLASS)/*.js
% }
	$(PERL) -i -p -e 's/\$$VERSION\s*=\s*".+?";/\$$VERSION = "$(PACKAGE_VERSION)";/;'  $(distdir)/lib/$(MJ_CLASS).pm

install-exec-hook:
	[ "$(PERL5LIB)" == "" ] || cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{.*# PERL5LIB}{use lib qw($(PERL5LIB)); # PERL5LIB}' $(BIN) || true
	cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{.*# LIBDIR}{use lib qw($(libdir)); # LIBDIR}' $(BIN)
	cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{^#!.*perl.*}{#!$(PERL)};' $(BIN)

% if ( ${package} eq 'callbackery' ) { 

all-local: share/messages.pot

clean-local:
	rm share/messages.pot

share/messages.pot: $(PM)
	mkdir -p share
	$(XGETTEXT) --language=perl --package-name=$(PACKAGE) --package-version=$(VERSION) --from-code=UTF-8 --keyword=trm:1 --output=share/messages.pot $(PM)
	touch share/en.po
	for lang in share/*.po; do \
		$(MSGMERGE) -U $$lang share/messages.pot; \
	done
% }

test:
	prove -w
