.PHONY: all init cpan test purge dist upload commit clean

MAKECPAN=make -C cpan -f mmm.mk

all: init
	$(MAKECPAN)

cpan: init
	$(MAKECPAN) all

test install purge: init
	$(MAKECPAN) $@

dist:
	$(MAKECPAN) $@

upload: commit dist
	cpan-upload cpan/[% dist_name %]-[% version %].tar.gz

init: tt.yaml cpan/mmm.mk

tt.yaml: Makefile
	mmm --tt-yaml

cpan/mmm.mk:
	mmm --cpan-makefile

commit: test
	mmm --$@

clean:
	rm -fr tt.yaml Makefile cpan META.yml
