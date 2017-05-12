.PHONY: $(shell ls)
.SILENT: 

#   00_load.t         01b_pod.t           01c_coverage.t  
#
 
MODULES  =  -MData::Dumper -MCarp  -MTest::More   -Mblib=../blib -Mv5.10


current = 01s_spelling.t
current = 01c_coverage.t
current = 05_minimumversion.t
current = 50_script_pl.t
#all: 01c_coverage.t
#all: 00_load.t
all: $(current)

vi = vi -p 

5* 0* 1*:
	perl -w -Mstrict -Mblib  $(MODULES)   $@  
pod:
	perldoc  ../blib/lib/Pg/Pcurse.pm
pode:
	perldoc  ../script/pcurse
cp:
	cp  ../blib/lib/Pg/Pcurse.pm    ../lib/Pg
	cp  ../blib/lib/Pg/Pcurse/*.pm  ../lib/Pg/Pcurse/
w:
	chmod -R u+w  ../blib/lib/Pg
vi: w
	$(vi) $(current)  ../blib/lib/Pg/Pcurse.pm  
viq: w
	$(vi)  $(current) ../blib/lib/Pg/Pcurse/Query1.pm  
vip: w
	$(vi)   $(current) ../script/pcurse
vim : w
	$(vi)  $(current) ../blib/lib/Pg/Pcurse/Misc.pm  
help:
	echo test vi viq vip vim pode pod 
test:
	make -sC .. test
