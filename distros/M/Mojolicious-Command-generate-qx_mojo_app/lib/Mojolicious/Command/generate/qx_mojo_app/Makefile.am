AUTOMAKE_OPTIONS =  foreign

SUBDIRS = frontend backend

EXTRA_DIST = VERSION PERL_MODULES COPYRIGHT LICENSE CHANGES AUTHORS

YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)
THIRDPARTY := $(shell pwd)/backend/thirdparty

dist-hook:
	$(PERL) -i -p -e 's/#VERSION#/$(PACKAGE_VERSION)/g;s/#YEAR#/$(YEAR)/g;s/#DATE#/$(DATE)/g;'  $(distdir)/README $(distdir)/COPYRIGHT

get-thirdparty-modules:
	[ -e $(THIRDPARTY)/bin/cpanm ] || mkdir -p $(THIRDPARTY)/bin && wget --no-check-certificate -O $(THIRDPARTY)/bin/cpanm cpanmin.us && chmod 755 $(THIRDPARTY)/bin/cpanm
	cat PERL_MODULES | PERL_CPANM_HOME=$(THIRDPARTY) PERL_CPANM_OPT="--notest --local-lib $(THIRDPARTY)" xargs $(PERL) $(THIRDPARTY)/bin/cpanm

#END

