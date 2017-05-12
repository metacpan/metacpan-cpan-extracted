
.SILENT:
.PHONY: $(shell ls)

#   main.t            config.t           mode.t  
#   dot.t             binmode.t          pod.t   

#  r01_general.t      r02a_eol.t         r02b_eol.t
#  r03_after.t        r04_maxlines.t     r05_patterns.t     
#  r06_blanklines.t   r07_comments.t     
#  w01_general.t      w02a_eol.t         w02b_eol.t 
#  w03_after.t        w04_maxlines.t     w05_patterns.t     
#  w06_blanklines.t   w07_comments.t

current = 01s_spelling.t
current = 01c_coverage.t
#all: dot.t
#all: binmode.t
all: $(current)
#all: rr01_general.t

0* r* w* main.t config.t mode.t pod.t binmode.t dot.t:
	perl -lw -Mblib -MData::Dumper  $@ 

w:
	chmod +w ../blib/lib/PerlIO/via/*
vi: w
	vi -p $(current) ../blib/lib/PerlIO/via/Skip.pm
cp:
	cp ../blib/lib/PerlIO/via/Skip.pm  ../lib/PerlIO/via/
test:
	make -C .. test
help:
	echo vi test
