#line 2 methmakename(code_accessor_h)

static void
THIS_OP_NAME(pTHX_ AV *av, const char *p_s, int dim, carray_form format)
{
    const TARG_ELT_TYPE *p = (TARG_ELT_TYPE *)p_s;
    array_stride tstride;
    array_count n;	/* Can't stop by inspecting p: stride may be 0 */

/*    p += mInd2ind(dim, ind, format);	*/
    if (!dim) {
	if (av) {
	  av_push(av, newSV_how(*p));
	} else {
	  dSP;

	  PUSHs(sv_2mortal(newSV_how(*p)));
	  PUTBACK;
	}
        return;
    }
    n = format[dim - 1].count;
    tstride =   format[dim - 1].stride;
  
    if (1 == dim) {
	if (av) {
	    I32 l = av_len(av);

	    av_extend(av, l + n);
            while (n--) {
                av_push(av, newSV_how(*p));
                p += tstride;
            }
	} else {
	    dSP;

	    EXTEND(SP, n);
            while (n--) {
                PUSHs(sv_2mortal(newSV_how(*p)));
                p += tstride;
            }
	    PUTBACK;
	}
    } else {
	if (av) {
            while (n--) {
		AV *av1 = newAV();	/* Will be extended by the callee */

                THIS_OP_NAME(aTHX_ av1, (char*)p, dim-1, format);
                av_push(av, newRV_noinc((SV*)av1));
                p += tstride;
            }
	} else {
	    dSP;
	    EXTEND(SP, n);
            while (n--) {
		AV *av1 = newAV();

                THIS_OP_NAME(aTHX_ av1, (char*)p, dim-1, format);
                PUSHs(sv_2mortal(newRV_noinc((SV*)av1)));
                p += tstride;
            }
	    PUTBACK;
	}
    }
}
