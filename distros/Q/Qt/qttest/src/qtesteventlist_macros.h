#ifndef QTESTEVENTLIST_MACROS_H
#define QTESTEVENTLIST_MACROS_H

#include <listclass_macros.h>
#include <QTestEvent>
#include <QtTest>
#include <QList>
#include <typeinfo>

template <class ItemList, class Item, const char *ItemSTR, const char* PerlName>
void XS_qtesteventlist_store( pTHX_ CV* cv)
{
    dXSARGS;
    if (items != 3)
        Perl_croak(aTHX_ "Usage: %s::store(array, index, value)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	index = (int)SvIV(ST(1));
        SV*	value = ST(2);
        SV *	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        smokeperl_object* valueo = sv_obj_info(value);
        if (!valueo || !valueo->ptr)
            XSRETURN_UNDEF;
        ItemList* list = (ItemList*)o->ptr;
        Item* point = (Item*)valueo->ptr;

        if ( 0 > index || index > list->size()+1 )
            XSRETURN_UNDEF;
        else if ( index == list->size() )
            list->append( point );
        else
            list->replace( index, point );

        RETVAL = newSVsv(value);
        ST(0) = RETVAL;
        sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

template <class ItemList, class Item, const char *ItemSTR, const char* PerlName>
void XS_qtesteventlist_storesize( pTHX_ CV* cv)
{
    dXSARGS;
    if (items != 2)
        Perl_croak(aTHX_ "Usage: %s::storesize(array, count)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
        SV*	array = ST(0);
        int	count = (int)SvIV(ST(1));
        AV *	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr || count < 0)
            XSRETURN_UNDEF;
        ItemList* list = (ItemList*)o->ptr;

        while ( count < list->size() )
            list->removeLast();

        PUTBACK;
        return;
    }
}

#define DEF_QTESTEVENTLIST_FUNCTIONS(ItemList,Item,ItemName,PerlName) \
namespace { \
char ItemList##STR[] = #ItemList;\
char ItemName##STR[] = #Item "*";\
char ItemName##PerlNameSTR[] = #PerlName;\
void (*XS_##ItemList##_at)(pTHX_ CV*)                    = XS_Vector_at<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_exists)(pTHX_ CV*)                = XS_ValueVector_exists<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_size)(pTHX_ CV*)                  = XS_ValueVector_size<ItemList, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_store)(pTHX_ CV*)                 = XS_qtesteventlist_store<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_storesize)(pTHX_ CV*)             = XS_qtesteventlist_storesize<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_clear)(pTHX_ CV*)                 = XS_ValueVector_clear<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_push)(pTHX_ CV*)                  = XS_Vector_push<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_pop)(pTHX_ CV*)                   = XS_ValueVector_pop<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_shift)(pTHX_ CV*)                 = XS_Vector_shift<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_unshift)(pTHX_ CV*)               = XS_Vector_unshift<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_splice)(pTHX_ CV*)                = XS_List_splice<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##__overload_op_equality)(pTHX_ CV*) = XS_ValueVector__overload_op_equality<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR, ItemList##STR>;\
\
}
#endif
