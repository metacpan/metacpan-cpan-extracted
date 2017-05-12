#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <sys/time.h>

struct timeval global_tv;
#define NOW \
	(gettimeofday(&global_tv,0),(((double)global_tv.tv_sec) + ((double)global_tv.tv_usec)/1000000.0))



MODULE = Statistics::CountAverage::XS		PACKAGE = Statistics::CountAverage::XS		

SV *
new(class_name,...)
	SV* class_name
INIT:
	AV *rec;
	AV *ary;
	AV *av;
	SV* len;
	if(items == 1){
		len = newSViv(10);
	}else{
		len = ST(1);
	}
CODE:
	rec = newAV();
	av_store(rec, 0, newSViv(0)); // count
	av_store(rec, 1, newSVnv(NOW)); // time
	av_store(rec, 2, newSVnv(.0)); // diff

	ary = newAV();
	av_store(ary, 0, newRV_noinc((SV*)rec));

	av = newAV();
	
	av_store(av, 0, newSVsv(len)); // len
	av_store(av, 1, newSViv(0)); // count
	av_store(av, 2, newSVnv(.0)); // time
	av_store(av, 3, newSVnv(NOW)); // last
	av_store(av, 4, newRV_noinc((SV*)ary)); // ary

    RETVAL = sv_bless(newRV_noinc((SV*)av), gv_stashsv(class_name, 0));
OUTPUT:
	RETVAL

void
count(self,...)
	SV* self
INIT:
	double now,diff;
	SV* add;

	AV* ary;
	AV* prev;
	AV *rec;
	AV* tmp;
	AV *av;

	SV** ptime;
	SV** count;
	SV** time;
	SV** len;
	SV** _count;
	SV** _diff;

	if(items == 1){
		add = newSViv(1);
	}else{
		add = ST(1);
	}
	av = (AV*)SvRV(self);
CODE:
	now = NOW;

	ary = (AV*)SvRV(*av_fetch(av,4,0));
	prev = (AV*)SvRV(*av_fetch(ary,av_len(ary),0));
	ptime = av_fetch(prev,1,0);
	diff = now - SvNV(*ptime);

	rec = newAV();
	av_store(rec, 0, newSVsv(add)); // count
	av_store(rec, 1, newSVnv(now)); // time
	av_store(rec, 2, newSVnv(diff)); // diff

	av_push(ary,newRV_noinc((SV*)rec));
	count = av_fetch(av, 1, 0); // count
	time = av_fetch(av, 2, 0); // time
	len = av_fetch(av, 0, 0); // time

	SvIV_set(*count, SvIV(*count) + SvIV(add));
	SvNV_set(*time, SvNV(*time) + diff);
	if(av_len(ary) >= SvIV(*len)){
		tmp = (AV*)SvRV(av_shift(ary));
		_count = av_fetch(tmp, 0, 0); // count
		_diff = av_fetch(tmp, 2, 0); // diff
		SvIV_set(*count, SvIV(*count) - SvIV(*_count));
		SvNV_set(*time,SvNV(*time) - SvNV(*_diff));
	}

SV*
speed(self)
	SV* self
INIT:
	AV* av;
	SV **count;
	SV **time;
	av = (AV*)SvRV(self);
CODE:
	count = av_fetch(av, 1, 0); // count
	time = av_fetch(av, 2, 0); // time
	RETVAL = newSVnv((double)SvIV(*count) / SvNV(*time));
OUTPUT:
	RETVAL

SV*
rate(self)
	SV* self
INIT:
	AV* av;
	AV* ary;
	SV **time;
	av = (AV*)SvRV(self);
CODE:
	ary = (AV*)SvRV(*av_fetch(av, 4, 0)); // ary
	time = av_fetch(av, 2, 0); // time
	RETVAL = newSVnv((double)(av_len(ary)+1) / SvNV(*time));
OUTPUT:
	RETVAL

void
check(self,...)
	SV* self
INIT:
	AV* av;
	SV **last;
	SV* to;
	double now;
	if(items == 1){
		to = newSViv(1);
	}else{
		to = ST(1);
	}
	av = (AV*)SvRV(self);
CODE:
	last = av_fetch(av, 3, 0); // last
	now = NOW;
	if(SvNV(*last) + SvIV(to) > now){
		XSRETURN_NO;
	}
	SvNV_set(*last,now);
	XSRETURN_YES;

SV*
avg(self)
	SV* self
INIT:
	AV* av;
	SV **count;
	AV *ary;
	av = (AV*)SvRV(self);
CODE:
	count = av_fetch(av, 1, 0); // count
	ary = (AV*)SvRV(*av_fetch(av, 4, 0)); // ary
	RETVAL = newSVnv((double)SvIV(*count) / (double)(av_len(ary)+1));
OUTPUT:
	RETVAL

SV*
stat(self)
	SV* self
INIT:
	AV *av;
	SV **count;
	SV **time;
	AV *ary;
	HV *hv;
	av = (AV*)SvRV(self);
CODE:
	count = av_fetch(av, 1, 0); // count
	ary = (AV*)SvRV(*av_fetch(av, 4, 0)); // ary
	time = av_fetch(av, 2, 0); // time
	hv = newHV();
	hv_store(hv,"speed",5,newSVnv((double)SvIV(*count) / SvNV(*time)),0);
	hv_store(hv,"rate",4,newSVnv((double)(av_len(ary)+1) / SvNV(*time)),0);
	hv_store(hv,"avg",3,newSVnv((double)SvIV(*count) / (double)(av_len(ary)+1)),0);

	RETVAL = newRV_noinc((SV*)hv);
OUTPUT:
	RETVAL
