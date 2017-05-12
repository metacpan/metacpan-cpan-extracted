#line 2 methmakename(code_0arg_h)

static void
THIS_OP_NAME(char *to_s, int dim, carray_form to_form)
{
    TARG_ELT_TYPE *to = (TARG_ELT_TYPE *)to_s;
    array_stride tstride;
    array_count n;	/* Can't stop by inspecting to: stride may be 0 */

    if (!dim) {
	DO_0OP(to[0]);
        return;
    }
    n = to_form[dim - 1].count;
    tstride =   to_form[dim - 1].stride;
  
    if (1 == dim) {
	while (n--) {
	  DO_0OP(*to);
	  to += tstride;
	}
    } else {
	while (n--) {
	  THIS_OP_NAME((char*)to, dim-1, to_form);
	  to += tstride;
	}
    }
}
