.PHONY: $(shell ls)
.SILENT: 
.DEFAULT_GOAL = fk_corrupt.pl

MODULES  =  -MData::Dumper -MCarp  
MODULES +=  -MTest::More   -Mblib=../blib -M5.010000

vim = vi -p -c 'set nofoldenable'

# 00_load.t           01s_spelling.t      05_minimumversion.t 
# 01b_pod.t           02_hasversion.t     07_strict.t
# 01c_coverage.t      03_meta.t           

current = 07_strict.t 
current = 22_dup_pks.t
current = 34_one_fk.t
current = 35_dup_fks.t
current = 30_fkeys.t
current = 31_attnum2attname.t

db      = lessons
table   = fk.person_1
table   = fk.house
pcopt   = -v

all: $(current)
#all = prove
prove:
	prove  *t

5* 4* 3* 2* 1* 0*:
	perl -w -Mstrict -Mblib  $(MODULES)   $@  
pk_corrupt.pl pc:
	perl -Mblib=../blib  ../blib/script/pk_corrupt.pl  $(pcopt) -d $(db)  $(table)
fk_corrupt.pl fc: 
	perl -Mblib=../blib  ../blib/script/fk_corrupt.pl  $(pcopt) -d $(db)  $(table)
cp:
	cp  ../blib/lib/Pg/Corruption.pm    ../lib/Pg
	cp  ../blib/script/*    ../script/
w:
	chmod -R u+w  ../blib/lib/Pg
	chmod -R u+w  ../blib/script
vi: w
	$(vim) $(current)  ../blib/lib/Pg/Corruption.pm  
pvi: w
	$(vim)  ../blib/script/pk_corrupt.pl  ../blib/lib/Pg/Corruption.pm
fvi: w
	$(vim)  ../blib/script/fk_corrupt.pl  ../blib/lib/Pg/Corruption.pm
pod:
	perldoc ../script/pk_corrupt.pl
help:
	echo  '[fk]vi test cp pod'
test:
	make -sC .. test
