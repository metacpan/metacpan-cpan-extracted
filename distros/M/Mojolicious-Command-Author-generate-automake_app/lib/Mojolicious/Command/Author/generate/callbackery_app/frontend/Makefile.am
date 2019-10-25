
AUTOMAKE_OPTIONS=foreign

EXTRA_DIST = $(shell find . -type d \( -name ".??*" -o -name "complied" -o -name "node_modules" \) -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -type f -print )

if BUILD_QOOXDOO_APP

all-local: build

node_modules:
	$(NPM) i

source: node_modules
	CALLBACKERY_QX=$(CALLBACKERY_QX) $(NPX) qx compile --feedback=false --erase

source-watch: node_modules
	CALLBACKERY_QX=$(CALLBACKERY_QX) $(NPX) qx compile --watch --feedback=false --erase

build: node_modules ../public/versions.json

clean: node_modules
	$(NPX) qx clean

../public/versions.json: $(EXTRA_DIST)
	CALLBACKERY_QX=$(CALLBACKERY_QX) $(NPX) qx compile --target=build --feedback=false --erase

endif
