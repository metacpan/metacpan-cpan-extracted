#ifndef PQT4_COMMON_H
#define PQT4_COMMON_H

char ** XS_unpack_charPtrPtr( SV *rv );
void XS_pack_charPtrPtr ( SV *st, char **s );
SV * class2pobj(IV iv, const char *class_name, int no_ptr);
IV pobj2class(SV *, const char *class_name, const char *func, const char *var);
int create_meta_data (char *sss, AV *signal_av, AV *slot_av, char **stringdata, uint **data);
void common_slots(int _id, void **_a, const char *stringdata, const uint *data, void *class_ptr, char *clFn);


#endif

