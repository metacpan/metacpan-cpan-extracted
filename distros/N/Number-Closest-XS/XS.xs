#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "ppport.h"
#include <math.h>

#if IVSIZE == 4
#define NUMBER NVTYPE
#define ABS(x) fabs(x)
#else
#define NUMBER long double
#define ABS(x) fabsl(x)
#endif

NUMBER sv2number(SV* sv) {
    I32 number_type;
    NUMBER res;
    if(SvIOK(sv)) {
        res = (NUMBER) SvIV(sv);
    } else if(SvNOK(sv)) {
        res = SvNV(sv);
    } else {
        number_type = looks_like_number(sv);
        if ((number_type & IS_NUMBER_IN_UV) && !(number_type & IS_NUMBER_NOT_INT)) {
            res = (NUMBER) SvIV(sv);
        } else {
            res = SvNV(sv);
        }
    }
    return res;
}

struct sv_with_distance {
    NUMBER distance;
    SV **svp;
};

void static add_to_the_list(
        struct sv_with_distance *list,
        int *length,
        int max,
        const struct sv_with_distance *item)
{
    int i;
    if (*length == 0
        || *length < max && list[*length - 1].distance <= item->distance)
    {
        /* add this item to the end of the list */
        list[*length].distance = item->distance;
        list[*length].svp = item->svp;
        (*length)++;
    } else if(list[*length - 1].distance > item->distance) {
        /* insert new element into list */
        for (i=0; list[i].distance <= item->distance; i++);
        memmove(list+i+1, list+i, (*length-i) * sizeof(struct sv_with_distance));
        list[i].distance = item->distance;
        list[i].svp = item->svp;
        if(*length < max) (*length)++;
    }
}

MODULE = Number::Closest::XS    PACKAGE = Number::Closest::XS    PREFIX = nclosx_
PROTOTYPES: DISABLE

AV*
nclosx_find_closest_numbers(center, source, ...)
        SV* center;
        AV* source;
    PREINIT:
        int length = 0;
        int amount = 1;
        int source_length;
        int i, j;
        NUMBER center_num, distance;
        struct sv_with_distance *sorted, item;
    CODE:
        if (items > 2) amount = SvIV(ST(2));
        RETVAL=newAV();
        sv_2mortal((SV*)RETVAL);
        source_length = av_len(source);
        if (source_length >= 0 && amount > 0) {
            center_num = sv2number(center);
            /* amount + 1 is to simplify memmove */
            Newx(sorted, amount + 1, struct sv_with_distance);
            for (i=0; i<= source_length; i++) {
                item.svp = av_fetch(source, i, 0);
                if (item.svp != NULL) {
                    item.distance = ABS(center_num - sv2number(*item.svp));
                    add_to_the_list(sorted, &length, amount, &item);
                }
            }
            for (i=0; i<length; i++) {
                av_push(RETVAL, newSVsv(*sorted[i].svp));
            }
            Safefree(sorted);
        }
    OUTPUT:
        RETVAL

AV*
nclosx_find_closest_numbers_around(center, source, ...)
        SV* center;
        AV* source;
    PREINIT:
        int source_length;
        int amount = 2;
        int i, j;
        NUMBER center_num;
        NUMBER distance;
        NUMBER abs_dist;
        struct sv_with_distance *left, *right, item;
        int left_len=0, right_len=0, left_pos=0, right_pos=0;
    CODE:
        if (items > 2) amount = SvIV(ST(2));
        RETVAL=newAV();
        sv_2mortal((SV*)RETVAL);
        source_length = av_len(source);
        if (source_length >= 0 && amount > 1) {
            /* amount + 1 is to simplify memmove */
            Newx(left, amount + 1, struct sv_with_distance);
            Newx(right, amount + 1, struct sv_with_distance);
            center_num = sv2number(center);
            for (i=0; i<= source_length; i++) {
                item.svp = av_fetch(source, i, 0);
                if (item.svp != NULL) {
                    item.distance = sv2number(*item.svp) - center_num;
                    if (item.distance <= 0) {
                        item.distance = ABS(item.distance);
                        add_to_the_list(left, &left_len, amount, &item);
                    } else {
                        add_to_the_list(right, &right_len, amount, &item);
                    }
                }
            }
            while (amount > 0 && (right_pos < right_len || left_pos < left_len)) {
                if (amount == 1 && right_pos < right_len && left_pos < left_len) {
                    /* get closest number */
                    if (left[left_pos].distance < right[right_pos].distance) {
                        av_unshift(RETVAL, 1);
                        av_store(RETVAL, 0, newSVsv(*left[left_pos++].svp));
                    } else {
                        av_push(RETVAL, newSVsv(*right[right_pos++].svp));
                    }
                    amount--;
                    break;
                }
                if (left_pos < left_len) {
                    av_unshift(RETVAL, 1);
                    av_store(RETVAL, 0, newSVsv(*left[left_pos++].svp));
                    amount--;
                }
                if (right_pos < right_len) {
                    av_push(RETVAL, newSVsv(*right[right_pos++].svp));
                    amount--;
                }
            }
            Safefree(left);
            Safefree(right);
        }
    OUTPUT:
        RETVAL
