.PHONY: default real_all test install dist

DATA=../tt.yaml
INCLUDE_PATH=[% include_path.join(':') %]
COPY_FILES=[% copy_files.join(' ') %]
TEMPLATE_FILES=[% template_files.join(' ') %]
DEPS=[% config_yaml %] ../Makefile

default: \
	$(COPY_FILES) \
	$(TEMPLATE_FILES) \
	README \
	MANIFEST.SKIP \
	Makefile \
	MANIFEST \
	real_all \

all test install dist purge: default
	@make $@

real_all:
	@make all

MANIFEST:
	make manifest

README:
	pod2text [% module_libpath %] > $@

Makefile: Makefile.PL
	perl Makefile.PL

[% FOR copy_file = copy_files %]
[% copy_file %]: ../[% copy_file %] $(DEPS)
	mkdir -p $(dir $@)
	cp ../$@ $@
[% END %]

Makefile.PL MANIFEST.SKIP: $(DEPS)
	tt-render --include_path=$(INCLUDE_PATH) --data=$(DATA) --output=$@ $@

[% FOR template_file = template_files %]
[% template_file %]: ../[% template_file %] $(DEPS)
	tt-render --include_path=$(INCLUDE_PATH) --data=$(DATA) --output=$@ $@
[% END %]

