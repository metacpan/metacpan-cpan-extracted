/* vim:set ts=4 sw=4 et syntax=c.doxygen: */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "convert.h"

static SV *
_convert_struct(const ps_node *node, enum type_preference prefer, const char *prefix)
{
    SV *result = NULL;
    const union ps_nodeval *v = &node->val;
    const struct ps_array *what =
        node->type == NODE_OBJECT
            ? &node->val.o.val
            : &node->val.a;

    if (node->type != NODE_OBJECT && what->len == 0 && prefer == PREFER_UNDEF) {
        result = newSVsv(&PL_sv_undef);
    } else {
        SV *a = NULL;
        if (prefer == PREFER_HASH || !what->is_array) {
            // len == 0 could be hash still
            a = (SV*)newHV();
            for (int i = 0; i < what->len; i++) {
                STRLEN len;
                char *key = SvPV(sv_2mortal(_convert_recurse(what->pairs[i].key, prefer, prefix)), len);
                SV   *val =                 _convert_recurse(what->pairs[i].val, prefer, prefix);

                hv_store((HV*)a, key, len, val, 0);
            }
        } else {
            a = (SV*)newAV();
            av_extend((AV*)a, what->len - 1);
            for (int i = 0; i < what->len; i++)
                av_push((AV*)a, _convert_recurse(what->pairs[i].val, prefer, prefix));
        }

        result = newRV_noinc(a);
        if (node->type == NODE_OBJECT) {
            char *typename = v->o.type;
            if (prefix) {
                SV *built = sv_2mortal(newSVpvf("%s::%s", prefix, typename));
                sv_bless(result, gv_stashsv(built, true));
            } else {
                sv_bless(result, gv_stashpv(typename, true));
            }
        }
    }

    return result;
}

SV *
_convert_recurse(const ps_node *node, enum type_preference prefer, const char *prefix)
{
    SV *result = NULL;

    const union ps_nodeval *v = &node->val;
    switch (node->type) {
        case NODE_STRING: result = newSVpv(v->s.val, v->s.len);            break;
        case NODE_INT:    result = newSViv(v->i);                          break;
        case NODE_FLOAT:  result = newSVnv(v->d);                          break;
        case NODE_BOOL:   result = newSVsv(v->b ? &PL_sv_yes : &PL_sv_no); break;
        case NODE_NULL:   result = newSVsv(&PL_sv_undef);                  break;
        case NODE_OBJECT: /* FALLTHROUGH */
        case NODE_ARRAY:  result = _convert_struct(node, prefer, prefix);  break;
    }

    return result;
}

