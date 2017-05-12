/* vim:set ts=4 sw=4 et syntax=c.doxygen: */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "convert.h"

SV *
_convert_recurse(const ps_node *node, int flags, const char *prefix)
{
    SV *result = NULL;

    const union nodeval *v = &node->val;
    char *typename = NULL;
    const struct array *what = NULL;
    SV *a = NULL;
    switch (node->type) {
        case NODE_STRING: result = newSVpv(v->s.val, v->s.len);            break;
        case NODE_INT:    result = newSViv(v->i);                          break;
        case NODE_FLOAT:  result = newSVnv(v->d);                          break;
        case NODE_BOOL:   result = newSVsv(v->b ? &PL_sv_yes : &PL_sv_no); break;
        case NODE_NULL:   result = newSVsv(&PL_sv_undef);                  break;
        case NODE_OBJECT:
            what = &node->val.o.val;
            typename = v->o.type;
            goto inside_array;
        case NODE_ARRAY: {
            what = &node->val.a;
        inside_array:
            if (!typename && what->len == 0 && (flags & PS_XS_PREFER_UNDEF)) {
                result = newSVsv(&PL_sv_undef);
            } else {
                if (flags & PS_XS_PREFER_HASH || !what->is_array) {
                    // len == 0 could be hash still
                    a = (SV*)newHV();
                    for (int i = 0; i < what->len; i++) {
                        STRLEN len;
                        char *key = SvPV(_convert_recurse(what->pairs[i].key, flags, prefix), len);
                        SV   *val =      _convert_recurse(what->pairs[i].val, flags, prefix);

                        hv_store((HV*)a, key, len, val, 0);
                    }
                } else {
                    a = (SV*)newAV();
                    av_extend((AV*)a, what->len - 1);
                    for (int i = 0; i < what->len; i++)
                        av_push((AV*)a, _convert_recurse(what->pairs[i].val, flags, prefix));
                }

                result = newRV(a);
                if (typename) {
                    bool should_free = false;
                    char *built = typename;
                    if (prefix) {
                        should_free = true;
                        size_t size = snprintf(NULL, 0, "%s::%s", prefix, typename);
                        built = malloc(size + 1);
                        snprintf(built, size + 1, "%s::%s", prefix, typename);
                    }

                    sv_bless(result, gv_stashpv(built, true));

                    if (should_free)
                        free(built);
                }
            }

            break;
        }
    }

    return result;
}

