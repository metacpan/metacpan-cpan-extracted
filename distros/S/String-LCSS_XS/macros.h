#define MALLOC(P,T,S) Newx(P,S,T)
#define CALLOC(P,T,S) Newxz(P,S,T)
#define REALLOC(P,T,S) Renew(P,S,T)
#define FREE(P) Safefree(P)
