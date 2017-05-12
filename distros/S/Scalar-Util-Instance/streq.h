/*
 * streq.h - Check string equality
 *
 * Provides: strEQ(a, b), strnEQ(a, b, n), strNE(a, b), strnNE(a, b, n)
 *
 */

#ifndef INLINED_STR_EQ_H
#define INLINED_STR_EQ_H

#if (!defined(__cplusplus__) || !defined(__STDC_VERSION__) ||  (__STDC_VERSION__ < 199901L)) && !defined(inline)
#define inline
#endif

#undef strnEQ
static inline int
strnEQ(const char* const x, const char* const y, size_t const n){
    register size_t i;
    for(i = 0; i < n; i++){
        if(x[i] != y[i]){
            return 0;
        }
    }
    return 1;
}

#undef strEQ
static inline int
strEQ(const char* const x, const char* const y){
    register size_t i;
    for(i = 0; ; i++){
        if(x[i] != y[i]){
            return 0;
        }
        else if(x[i] == '\0'){
            return 1; /* y[i] is also '\0' */
        }
    }
    return 1; /* not reached */
}

#undef  strnNE
#define strnNE(a, b, n) (!strnEQ(a, b, n))

#undef  strNE
#define strNE(a, b) (!strEQ(a, b))

#endif /* !INLINED_STR_EQ_H */
