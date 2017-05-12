#ifndef MY_RUBY_PORTABILITY_H
#define MY_RUBY_PORTABILITY_H
#if MY_RUBY_VERSION_INT < 190

#define rb_str_set_len(s, l) ((void)(RSTRING_LEN(s) = (l)))

#define rb_errinfo() (ruby_errinfo)
#define rb_set_errinfo(e) ((void)(ruby_errinfo = e))

#endif


#ifndef RFLOAT_VALUE
#define RFLOAT_VALUE(v) (RFLOAT(v)->value)
#endif

#endif
