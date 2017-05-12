.PHONY: $(shell ls)
.SILENT: 

#  00_load.t            01b_pod.t           01c_coverage.t  
#  02_hasversion.t      03_meta.t           04_dependencies.t-   
#  05_minimumversion.t- 07_strict.t
#  10_basic.t  11_tel2num.t 20_mnemonic.t   21_combine.t
#  111_rel2num.t        12_tel_func.t       13_beautify.t   14_str_pairs.t
#  15_seg_words.t       16_area_code.t  
 
bpath = ../blib/lib/Telephone/Mnemonics/
MODULES  =  -MData::Dumper -MCarp   -M5.010000
MODULES +=  -Mblib=../blib  #=MTest::More
vi =  vi  -pc 'set nofoldenable'

current = 01b_pod.t
current = 01c_coverage.t  
current = 05_minimumversion.t
current = 10_basic.t
current = 11_tel2num.t
current = 12_phone.t
current = 13_beautify.t
current = 14_str_pairs.t
current = 15_seg_words.t
current = 16_area_code.t
current = 17_partial_codes.t
current = 20_mnemonic.t
current = 21_combine.t
current = 30_phone.t
current = 31_instance.t
current = 32_buildargs.t
current = 33_role_words.t
current = 34_role_term.t
current = 01s_spelling.t
current = 04_dependencies.t
current = 08_scripts.t
current = 09_legal.t
current = 50_script_pl.t


#all: mpod
all: $(current)

tel2num tel_mnemonic:
	perl -Mblib=../blib/lib  ../script/$@.pl $(if $(findstring tel2num,$@),ameritrade,2628)

5* 3* 2* 1* 0*:
	perl -w -Mstrict -Mblib  $(MODULES)   $@  
pod:
	PAGER="less" perldoc  ../blib/lib/Telephone/Mnemonic/US.pm
spell:
	$(vi) 06_spelling.t  ../blib/lib/Telephone/Mnemonic/US.pm
npod:
	PAGER="less" perldoc  ../blib/lib/Telephone/Mnemonic/US/Number.pm
mpod:
	PAGER="less" perldoc  ../blib/lib/Telephone/Mnemonic/US/Math.pm
cp:
	cp  ../blib/lib/Telephone/Mnemonic/*.pm     ../lib/Telephone/Mnemonic/
	cp  ../blib/lib/Telephone/Mnemonic/US/*.pm  ../lib/Telephone/Mnemonic/US/
	cp  ../blib/lib/Telephone/Mnemonic/US/Roles/*.pm  ../lib/Telephone/Mnemonic/US/Roles/
w: 
	chmod -R u+w  ../blib/lib/Telephone
vi :  w
	$(vi) ../blib/lib/Telephone/Mnemonic/US.pm  
vip :  w
	$(vi) +/NAME ../blib/lib/Telephone/Mnemonic/US.pm  
t2n t2m :  w
	$(vi) ../script/tel2num.pl  ../blib/lib/Telephone/Mnemonic/US.pm  
roles:  w
	$(vi) $(current)  ../blib/lib/Telephone/Mnemonic/US/Phone.pm  ../blib/lib/Telephone/Mnemonic/US/Roles/Words.pm  ../blib/lib/Telephone/Mnemonic/US/Roles/Term.pm
vphone:  w
	#$(vi) $(current)  ../blib/lib/Telephone/Mnemonic/US/Phone.pm  ../blib/lib/Telephone/Mnemonic/US/Roles/Words.pm  ../blib/lib/Telephone/Mnemonic/US/Number.pm
	$(vi) $(current)  ../blib/lib/Telephone/Mnemonic/US/Phone.pm  ../blib/lib/Telephone/Mnemonic/Phone.pm  ../blib/lib/Telephone/Mnemonic/US/Number.pm
#$(bpath)/US/Phone.pm # $(bpath)/US/Phone.pm   $(bpath)/US/Words.pm

bnum: w
	PAGER="less" $(vi) -p  $(current) ../blib/lib/Telephone/Mnemonic/US/Number.pm 
b: w
	PAGER="less" $(vi) -p  $(current) ../blib/lib/Telephone/Mnemonic/US.pm 
bmath: w
	PAGER="less" $(vi) -p  $(current) ../blib/lib/Telephone/Mnemonic/US/Math.pm 
	
vipod: w
	$(vi) -c 'syntax clear' '+/__END__' ../blib/lib/Telephone/US/US.pm 
math: w
	$(vi) ../blib/lib/Telephone/Mnemonic/Math.pm  
test:
	make -C .. test
help:
	echo pod vi num b bmath  vipod math test t2n t2m  el2num tel_numeric vphone
	echo tel2num tel_mnemonic t2n t2m npod mpod vip t2n atel t2m tel bnum vipod test
