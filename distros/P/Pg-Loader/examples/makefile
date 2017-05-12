.PHONY: $(shell ls)
.SILENT:

#args= -n 3  #-dv   # -c /bin/touch  -p pid

MODULES  =  -MData::Dumper    -Mstrict -Mblib=../blib

OPTS     =  -lw
args     = -c j.conf -V  -s   dax  -d
args     = -c j.conf -TV  -si   exam   -d

#all: try
#all: pod
#all: debug
all: pgloader


try e*:
	./perl $(OPTS) $(MODULES) $@
pgloader:
	#../script/$@.pl $(args)
	../script/pgloader.pl -c u.conf exam -d
check_all:
	../script/pgloader.pl   -c j.conf -TV  -si   exam   -d
	../script/pgloader.pl 	-c u.conf exam -d
verbose: clean
	../script/pgloader.pl $(args) -v
debug:
	../script/pgloader.pl $(args) -d
help:
	../script/pgloader.pl $(args) -h
w:
	chmod -R u+w  ../blib/lib/Pg
lvi: w
	vim  ../blib/lib/Pg/Loader.pm  
ovi: w
	vim  ../blib/lib/Pg/Loader/Options.pm  
mvi: w
	vim  ../blib/lib/Pg/Loader/Misc.pm  
mmvi: w
	vim  ../blib/lib/Pg/Loader/Misc_2.pm  
uvi: w
	vim  ../blib/lib/Pg/Loader/Update.pm  
yvi: w
	vim  ../blib/lib/Pg/Loader/Copy.pm
gvi: w
	vim  ../blib/lib/Pg/Loader/Log.pm  
qvi: w
	vim  ../blib/lib/Pg/Loader/Query.pm  
cvi: w
	vim  ../blib/lib/Pg/Loader/Columns.pm  
vi: w
	vim  ../script/pgloader.pl
cp:
	cp  ../blib/lib/Pg/Loader.pm    ../lib/Pg
	cp  ../blib/lib/Pg/Loader/*     ../lib/Pg/Loader

pod:
	perldoc  ./pgloader.pl
p:
	perldoc pgloader.pl
podl:
	perldoc ../blib/lib/Pg/Loader.pm
clean:
	rm -f r_log* r_data* log/*
