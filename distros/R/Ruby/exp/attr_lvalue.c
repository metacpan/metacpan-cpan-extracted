
struct plrb_attr
{
	VALUE recv;
	ID    getter;
	ID    setter;
};

static int
plrb_mg_attr_set(pTHX_ SV* sv, MAGIC* mg)
{
	struct plrb_attr* attr = (struct plrb_attr*)mg->mg_ptr;
	VALUE val;

	if(!attr->setter){ /* first call */
		const char* getter = rb_id2name(attr->getter);
		STRLEN len = strlen(getter)+1;

		char smallbuf[128];
		char* buf;
		volatile VALUE strbuf;

		if(len < sizeof(smallbuf)){
			buf = smallbuf;
		}
		else{
			strbuf = rb_str_buf_new((long)len);
			buf = RSTRING_PTR(strbuf);
		}

		/* "attr" + "=" + "\0" */

		memcpy(buf, getter, len-1);
		buf[len-1] = '=';
		buf[len]   = '\0';

		attr->setter = rb_intern(buf);
	}

	val = SV2VALUE(sv);

	do_funcall_protect(aTHX_ attr->recv, attr->setter, 1, &val, FALSE);

	return 0;
}


MGVTBL plrb_attr_vtbl = {
	NULL, /* mg_get */
	plrb_mg_attr_set,
	NULL, /* mg_len */
	NULL, /* mg_clear */
	NULL, /* mg_free */
	NULL, /* mg_copy */
	NULL, /* mg_dup */
	NULL  /* mg_local */
};


XS(XS_Ruby_method_dispatcher);
XS(XS_Ruby_method_dispatcher)
{
	dXSARGS;
	VALUE self;
	VALUE result;
	ID method = (ID)XSANY.any_iv;

	if(items == 0) croak("Not enough arguments for %s", rb_id2name(method));

	self   = ruby_self(ST(0));
	result = plrb_funcall_protect(self, method, (items - 1), &ST(1));

	if(GIMME_V != G_VOID){
		VALUE ret_tab;
		ID retval_id = method;
		VALUE v;
		SV* sv;
		struct plrb_attr attr = { self, method, (ID)0 };

		/* obj[ret_tab][result] = result  */


		if(OBJ_FROZEN(self) || items != 1){
			sv = VALUE2SV(result);
		}
		else{
			ret_tab = rb_ivar_get_defaultf(self, id_ret_tab, obj_new);

			if(NIL_P(v = rb_attr_get(ret_tab, retval_id))){

				sv = newSVvalue(result);

				rb_ivar_set(ret_tab, retval_id, v = any_new_noinc(sv));

				sv_magicext(sv, NULL, PERL_MAGIC_ext, &plrb_attr_vtbl, (char*)&attr, sizeof(attr));

			}
			else{
				sv = valueSV(v);

				sv_set_value2sv(sv, result);
			}
		}

		ST(0) = sv;

		XSRETURN(1);
	}
	else{
		XSRETURN_EMPTY;
	}
}
