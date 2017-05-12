.PHONY: $(shell ls)
.SILENT: 

#all:  00_main.t      01_wordlength.t    02_words.t  
#all:  03_subword.t   04_strip.t         05_Substr.t
#all:  06_word.t      07_verify.t        08_space.t
#all:  09_reverse.t   10_right.t         11_Pos.t  
#all:  12_overlay.t   13_Length.t        14_left.t
#all:  15_lastpos.t   16_insert.t        17_delword.t
#all:  18_delstr.t    19_countstr.t      20_copies.t
#all:  21_compare.t   22_changestr.t     23_center.t
#all:  24_xrange.t    25_wordindex.t     26_translate.t
#all:  27_datatype.t  28_wordpos.t       29_Abbrev.t
#all:  30_b2d.t       31_d2x.t           32_sign.t
#all:  33_x2b.t       34_b2x.t           35_x2c.t
#all:                 37_x2d.t           38_c2x.t
#all:  39_d2b.t       pod.t              pod-coverage.t

current = 00_load.t
current = 01s_spelling.t
current = 01c_coverage.t
current = 26_translate.t

all:  pod-coverage.t
all: $(current)


MODULES  =  -MData::Dumper -MCarp  -MParams::Validate=':all'
MODULES +=  -MTest::More   -MTest::Exception  # -MString::Rexx=':all'

p* 0* 1* 2* 3* 4*:
	perl -w -Mstrict -Mblib=../blib/lib  $(MODULES)   $@  

w:
	chmod +w ../blib/lib/String/Rexx.pm
vi: w
	vi -p $(current) ../blib/lib/String/Rexx.pm
cp:
	cp ../blib/lib/String/Rexx.pm  ../lib/String/
test:
	make -sC .. test
help:
	echo test vi 
