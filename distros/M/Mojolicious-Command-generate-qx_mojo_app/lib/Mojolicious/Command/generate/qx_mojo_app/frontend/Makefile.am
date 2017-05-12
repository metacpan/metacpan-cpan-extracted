% my $p = shift;

AUTOMAKE_OPTIONS=foreign
CLASS=<%= $p->{name} %>

EXTRA_DIST = config.json Manifest.json source/index.html $(shell find source/class/ -name "*.js") $(wildcard source/translation/*.po source/resource/*/*.png  source/resource/*/*.gif)

if BUILD_QOOXDOO_APP

GENTARGETS := lint pretty migration translation api

.PHONY: $(GENTARGETS) source

source: source/script/$(CLASS).js

$(GENTARGETS):
	$(QOOXDOO_PATH)/tool/bin/generator.py -m QOOXDOO_PATH:$(QOOXDOO_PATH) -m CACHE:./cache $@

source/script/$(CLASS).js: $(shell find source/class/ -name "*.js")
	$(QOOXDOO_PATH)/tool/bin/generator.py -m QOOXDOO_PATH:$(QOOXDOO_PATH) -m CACHE:./cache source

endif

clean-local:
	test -d ./cache && rm -r ./cache || true
	test -f source/script/$(CLASS).js && rm source/script/* || true

