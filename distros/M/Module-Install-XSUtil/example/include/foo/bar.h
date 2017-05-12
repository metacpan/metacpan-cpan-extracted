/* foo/bar.h for testing */

#define X(name) int name

#ifndef __attribute__warn_unused_result__
#ifdef HASATTRIBUTE_WARN_UNUSED_RESULT
#   define __attribute__warn_unused_result__ __attribute__((warn_unused_result))
#else
#   define __attribute__warn_unused_result__
#endif
#endif /* !defined(__attribute__warn_unused_result__) */

#ifndef PERL_UNUSED_DECL
#  if defined(HASATTRIBUTE_UNUSED) && !defined(__cplusplus) && defined(__attribute__unused__)
#    define PERL_UNUSED_DECL __attribute__unused__
#  else
#    define PERL_UNUSED_DECL
#  endif
#endif

X(bar_is_ok)(
	X(a) PERL_UNUSED_DECL, X(b), X(c)
) __attribute__warn_unused_result__;


struct mi_xsutil_testing {
    void* (*not_a_function)(int a PERL_UNUSED_DECL, int);
};
