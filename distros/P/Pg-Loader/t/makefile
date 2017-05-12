.PHONY: $(shell ls)
.SILENT: 

#   00_load.t         		01b_pod.t                 01c_coverage.t  
#   02_hasversion.t             02_meta.t                 04_dependencies.t
#   05_minimumversion.t                                   07.strict.t
#   10_simplify_ini.t           11_ini_conf.t             12_error_check.t
#   13_subset.t                 14_check_copy_grammar.t   15_copy_param.t
#   16_combine.t                17_switch2update.t        18_sample.t
#   20_disable_indexes.t        21_enable_indexes.t       22_stop_input.t
#   24_sql_clause.t
#   31_add_defaults.t           32_filter_ini.t
#   40_kwalitee.t
#   52_range2list     		53_schema_name.t          54_get_columns_names.t
#   55_field_nums_reqe.t        56_requested_cols.t       
 
MODULES  =  -MData::Dumper -MCarp  
MODULES +=  -MTest::More   -Mblib=../blib -M5.010000

vim = vi -p -c 'set nofoldenable'


current = 00_load.t
current = 01s_spelling.t
current = 01c_coverage.t
current =  04_dependencies.t
current =  10_legal.t
current =  50_script_pl.t
current =  20_disable_indexes.t 

all: $(current)
#all = prove
prove:
	prove  *t

5* 4* 3* 2* 1* 0*:
	perl -w -Mstrict -Mblib  $(MODULES)   $@  
check_all:
	../script/pgloader.pl       -c j.conf -TV  -si   exam   -d
	../script/pgloader.pl -c u.conf exam -d
cp:
	cp  ../blib/lib/Pg/Loader.pm    ../lib/Pg
	cp  ../blib/lib/Pg/Loader/*.pm  ../lib/Pg/Loader/
w:
	chmod -R u+w  ../blib/lib/Pg
lvi: w
	$(vim) $(current)  ../blib/lib/Pg/Loader.pm  
qvi: w
	$(vim) $(current)  ../blib/lib/Pg/Loader/Query.pm  
mvi: w
	$(vim) $(current)  ../blib/lib/Pg/Loader/Misc.pm  
yvi: w
	$(vim) $(current)  ../blib/lib/Pg/Loader/Copy.pm  
uvi: w
	$(vim) $(current)  ../blib/lib/Pg/Loader/Update.pm  
mmvi: w
	$(vim) $(current) ../blib/lib/Pg/Loader/Misc_2.pm  
ovi: w
	$(vim) $(current)  ../blib/lib/Pg/Loader/Options.pm  
cvi: w
	$(vim) $(current)  ../blib/lib/Pg/Loader/Columns.pm  
gvi: w
	$(vim) $(current)  ../blib/lib/Pg/Loader/Log.pm  
vi: w
	$(vim) $(current)  ../script/pgloader.pl
pod:
	perldoc ../script/pgloader.pl
podl:
	perldoc ../blib/lib/Pg/Loader.pm
help:
	echo podl pod gvi cvi ovi mmvi uvi yvi mvi qvi lvi test
test:
	make -sC .. test
