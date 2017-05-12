#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "queue_internal.h"

MODULE = Queue::Mmap		PACKAGE = Queue::Mmap

SV *
create(classname,filename,que_len,rec_len)
	SV *classname
	SV *filename
	SV* que_len
	SV* rec_len
INIT:
	struct object * obj;
CODE:
	obj = new_queue();
	calc_queue(obj,SvPV_nolen(filename),SvIV(que_len),SvIV(rec_len));
	init_queue(obj);
	
	RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(obj))), gv_stashsv(classname, 0));
OUTPUT:
	RETVAL

SV*
pop(self)
	SV* self
INIT:
	struct object * obj;
	obj = INT2PTR(struct object*, SvIV(SvRV(self)));
CODE:
	if(!(RETVAL = pop_queue(obj))){
		XSRETURN_UNDEF;
	}
OUTPUT:
	RETVAL

SV*
top(self)
	SV* self
INIT:
	struct object * obj;
	obj = INT2PTR(struct object*, SvIV(SvRV(self)));
CODE:
	if(!(RETVAL = top_queue(obj))){
		XSRETURN_UNDEF;
	}
OUTPUT:
	RETVAL
	
void
drop(self)
	SV* self
INIT:
	struct object * obj;
	obj = INT2PTR(struct object*, SvIV(SvRV(self)));
CODE:
	drop_queue(obj);

void
push(self,value)
	SV * self;
	SV * value;
INIT:
	struct object * obj;
	void *strp;
	int strl;
	STRLEN strlo;
	obj = INT2PTR(struct object*, SvIV(SvRV(self)));
	strp = (void *)SvPV(value, strlo);
	strl = (int)strlo;
PPCODE:
	if(strl > obj->rec_len * (obj->que_len - 1)){
		XSRETURN_UNDEF;
	}
	push_queue(obj,strp,strl);
	XPUSHs(sv_2mortal(newSVnv(obj->wait_push)));
	if(GIMME_V == G_ARRAY){
		XPUSHs(sv_2mortal(newSVnv(obj->wait_lock)));
	}

void
DESTROY(self)
	SV* self
INIT:
	struct object * obj;
	obj = INT2PTR(struct object*, SvIV(SvRV(self)));
CODE:
	free_queue(obj);

void
stat(self)
	SV* self
INIT:
	struct object * obj;
	obj = INT2PTR(struct object*, SvIV(SvRV(self)));
PPCODE:
	XPUSHs(sv_2mortal(newSViv(obj->q->top)));
	XPUSHs(sv_2mortal(newSViv(obj->q->bottom)));
	XPUSHs(sv_2mortal(newSViv(obj->que_len)));
	XPUSHs(sv_2mortal(newSViv(obj->rec_len)));

SV*
length(self)
	SV* self
INIT:
	int t,b;
	struct object * obj;
	obj = INT2PTR(struct object*, SvIV(SvRV(self)));
CODE:
	t = obj->q->top;
	b = obj->q->bottom;
	if(t <= b){
		RETVAL = newSViv(b - t);
	}else{
		RETVAL = newSViv(obj->que_len + b - t);
	}
OUTPUT:
	RETVAL


