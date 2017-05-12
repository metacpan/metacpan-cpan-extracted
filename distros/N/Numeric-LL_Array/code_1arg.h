#line 2 methmakename(code_1arg_h)

static void
THIS_OP_NAME(const char *from_s, char *to_s, int dim, carray_form from_form, carray_form to_form)
{
    const SOURCE_ELT_TYPE *from = (const SOURCE_ELT_TYPE *) from_s;
    TARG_ELT_TYPE *to = (TARG_ELT_TYPE *)to_s;
    array_stride fstride;
    array_stride tstride;
    array_count n;	/* Can't stop by inspecting to: stride may be 0 */

    if (!dim) {
	DO_1OP(to[0], from[0]);
        return;
    }
    n = to_form[dim - 1].count;
    fstride = from_form[dim - 1].stride;
    tstride =   to_form[dim - 1].stride;
  
    if (1 == dim) {
	while (n--) {
	  DO_1OP(*to, *from);
	  from += fstride;
	  to += tstride;
	}
    } else {
	while (n--) {
	  THIS_OP_NAME((const char*)from, (char*)to, dim-1, from_form, to_form);
	  from += fstride;
	  to += tstride;
	}
    }
}
