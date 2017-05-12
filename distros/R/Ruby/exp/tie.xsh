
SV*
_as_hash(self, rhs, flag)
	SV* self
PREINIT:
	HV* hv = newHV();
CODE:
	sv_magic((SV*)hv, self, PERL_MAGIC_tied, Nullch, 0);
	RETVAL = newRV_noinc((SV*)hv);
OUTPUT:
	RETVAL

SV*
_as_array(self, rhs, flag)
	SV* self
PREINIT:
	AV* av = newAV();
CODE:
	sv_magic((SV*)av, self, PERL_MAGIC_tied, Nullch, 0);
	RETVAL = newRV_noinc((SV*)av);
OUTPUT:
	RETVAL



VALUE
FIRSTKEY(self)
	VALUE self
PREINIT:
	VALUE keys;
	VALUE size;
CODE:
	keys = plrb_funcall_protect(self, rb_intern("keys"), 0, NULL);
	size = plrb_funcall_protect(keys, rb_intern("size"), 0, NULL);
	if(NUM2INT(size) > 0){
		RETVAL = plrb_funcall_protect(keys, rb_intern("shift"), 0, NULL);
		rb_iv_set(self, "_iter_keys", keys);
	}
	else{
		XSRETURN_UNDEF;
	}
OUTPUT:
	RETVAL

VALUE
NEXTKEY(self, lastkey = N/A)
	VALUE self
PREINIT:
	VALUE keys;
	VALUE size;
CODE:
	keys = rb_iv_get(self, "_iter_keys");
	size = plrb_funcall_protect(keys, rb_intern("size"), 0, NULL);
	if(NUM2INT(size) > 0){
		RETVAL = plrb_funcall_protect(keys, rb_intern("shift"), 0, NULL);
	}
	else{
		XSRETURN_UNDEF;
	}
OUTPUT:
	RETVAL

