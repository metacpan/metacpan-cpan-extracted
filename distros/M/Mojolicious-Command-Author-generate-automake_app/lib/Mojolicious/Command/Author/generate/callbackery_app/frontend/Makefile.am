
AUTOMAKE_OPTIONS=foreign

EXTRA_DIST = compile.js  compile.json  config.json Manifest.json package.json package-lock.json $(shell find source -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -type f -print )

if BUILD_QOOXDOO_APP

all-local: build

.PHONY: source source-watch node_modules build clean

node_modules: node_modules/.setup

source: node_modules compiled/source/.built


source-watch: node_modules
	CALLBACKERY_QX=$(CALLBACKERY_QX) $(NPX) qx compile --watch --feedback=false --erase

build: node_modules ../public/.built

clean: node_modules
	$(NPX) qx clean

../public/.built: $(EXTRA_DIST) Makefile
	CALLBACKERY_QX=$(CALLBACKERY_QX) $(NPX) qx compile --target=build --feedback=false --erase
	touch $@

compiled/source/.built: $(EXTRA_DIST) Makefile
	CALLBACKERY_QX=$(CALLBACKERY_QX) $(NPX) qx compile --feedback=false --erase
	touch $@

node_modules/.setup: package.json
	$(NPM) i
	touch $@

endif
