#!/bin/bash

export LC_ALL=C.UTF-8
.PHONY: all check tests
all:

check tests: pdf

MACHINES:=
define add-machine
  # 1: local-name  2: ssh-name
  #$$(warning Defining $1/$2)
  HOST_$1:=$2
  MACHINES+=$1
download: download-$1
endef

-include local-machines.mk

DOT_MACHINES=$(sort $(MACHINES) $(patsubst %.rawcmd,%,$(wildcard *.rawcmd)))

.DELETE_ON_ERROR:

.PHONY: rawcmd dot ref pdf fullref
rawcmd: $(addsuffix .rawcmd,$(DOT_MACHINES))

dot: $(addsuffix .dot,$(DOT_MACHINES))

ref: $(addsuffix .ref.dot,$(DOT_MACHINES))
fullref: download
	$(MAKE) ref

pdf: $(addsuffix .pdf,$(DOT_MACHINES))

STORAGE2DOT=../local-run storage2dot
DOT=dot

.SECONDARY: $(addsuffix .ref.data,$(DOT_MACHINES))
.SECONDARY: $(addsuffix .data,$(DOT_MACHINES))

.PHONY: download
download: $(addprefix download-,$(MACHINES))

download-%:
	$(STORAGE2DOT) --remote $(HOST_$*) -c --record $*.rawcmd -o $*.ref.data.downloaded
	./local-cleanup-data $*
	$(MAKE) $*.ref.data
	diff -ub $*.ref.data.downloaded $*.ref.data
	$(RM) $*.ref.data.downloaded
	$(STORAGE2DOT) --data $*.ref.data -o $*.ref.dot

%.ref.data: %.rawcmd
	$(STORAGE2DOT) --replay $< -c -o $@

%.data: %.rawcmd %.ref.data ../lib/StorageDisplay/Collect.pm
	$(STORAGE2DOT) --replay $< -c -o $@
	diff -u $*.ref.data $*.data
	
%.dot: %.data ../lib/StorageDisplay.pm
	$(STORAGE2DOT) --data $< -o $@
	if [ -e $*.ref.dot ]; then diff -u $*.ref.dot $@ ; fi

%.pdf: %.dot
	$(DOT) -Tpdf $< > $@

.PHONY: clean distclean
clean::
	$(RM) $(foreach s,data dot pdf,$(addsuffix .$s,$(DOT_MACHINES)))

.PHONY: cleanref
cleanref:: clean
	$(RM) $(foreach s,data dot pdf,$(addsuffix .ref.$s,$(DOT_MACHINES)))
