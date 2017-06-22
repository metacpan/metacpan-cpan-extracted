% my $p = shift;

AUTOMAKE_OPTIONS=foreign
CLASS=<%= $p->{name} %>

EXTRA_DIST = config.json Manifest.json source/index.html \
	$(shell find source/class source/resource source/translation -type d \( -name ".??*" -o -name "build" \) -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -type f -print )

if BUILD_QOOXDOO_APP

GENTARGETS := lint pretty migration translation api source-all source-hybrid source

.PHONY: $(GENTARGETS)

$(GENTARGETS): $(shell find source/class/ -type f) config.json
	$(QOOXDOO_PATH)/tool/bin/generator.py -m QOOXDOO_PATH:$(QOOXDOO_PATH) -m CACHE:./cache $@

endif

# clean-local:
deepclean:
	test -d ./cache && rm -r ./cache || true
	test -f source/script/$(CLASS).js && rm source/script/* || true
