% my $p = shift;
AUTOMAKE_OPTIONS =  foreign

QX_CLASS = <%= $p->{name} %>
MJ_CLASS = <%= $p->{class} %>
MJ_SCRIPT = <%= $p->{name} %>

BIN = bin/$(MJ_SCRIPT).pl bin/$(MJ_SCRIPT)-source-mode.sh

PM :=  $(shell find lib/ thirdparty/lib/perl5 -name "*.pm")  $(shell test -f thirdparty && find thirdparty/lib/perl5 -type f)

POD :=  $(shell find lib/ -name "*.pod")

RES :=  $(shell test -d public/resource && find public/resource -type f)

TEMPL := $(shell test -d templates && find templates -type f)

PUB = public/script/$(QX_CLASS).js public/index.html $(RES)

EXTRA_DIST = $(wildcard t/*.t) $(ETC) $(BIN) $(PM) $(POD) $(PUB) $(TEMPL)

YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)

datadir = $(prefix)
nobase_data_DATA = $(PM) $(POD) $(PUB) $(ETC) $(TEMPL)

dist_bin_SCRIPTS = $(BIN)

if BUILD_QOOXDOO_APP

public/script/$(QX_CLASS).js: $(shell find ../frontend/source/class/$(QX_CLASS) -name "*.js") $(QOOXDOO_PATH)/framework/config.json ../configure
	cd ../frontend && $(QOOXDOO_PATH)/tool/bin/generator.py -m QOOXDOO_PATH:$(QOOXDOO_PATH) -m CACHE:./cache -m BUILD_PATH:../backend/public build
	$(PERL) -i -p -e 's/#VERSION#/$(PACKAGE_VERSION)/g;s/#YEAR#/$(YEAR)/g;s/#DATE#/$(DATE)/g;' public/index.html public/script/$(QX_CLASS).js

endif

install-exec-hook:
	[ "$(PERL5LIB)" != "" ] && cd "$(DESTDIR)$(bindir)" && $(PERL) -i -p -e 's{.*# PERL5LIB}{use lib qw($(PERL5LIB)); # PERL5LIB}' *.pl || true
	cd "$(DESTDIR)$(bindir)" && $(PERL) -i -p -e 's{^#!.*perl.*}{#!$(PERL)};' *.pl

dist-hook:
	$(PERL) -i -p -e '"$(PACKAGE_VERSION)" =~ /(\d+)\.(\d+)\.(\d+)/ and $$v = sprintf("%d.%03d%03d",$$1,$$2,$$3) and s/^\$$VERSION\s+=\s+".+?"/\$$VERSION = "$$d"/;'  $(distdir)/lib/$(MJ_CLASS).pm


