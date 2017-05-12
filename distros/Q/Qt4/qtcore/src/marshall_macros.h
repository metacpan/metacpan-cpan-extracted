/***************************************************************************    
  marshall_macros.h  -  Useful template based marshallers for QLists, QVectors
                        and QLinkedLists
                             -------------------
    begin                : Thurs Jun 8 2008
    copyright            : (C) 2008 by Richard Dale
    email                : richard.j.dale@gmail.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef MARSHALL_MACROS_H
#define MARSHALL_MACROS_H

#include <QtCore/qlist.h>
#include <QtCore/qlinkedlist.h>
#include <QtCore/qvector.h>

#include "binding.h"
#include "marshall.h"
#include "util.h"

#define DEF_HASH_MARSHALLER(HashIdent,Item) namespace { char HashIdent##STR[] = #Item; }  \
        Marshall::HandlerFn marshall_##HashIdent = marshall_Hash<Item,HashIdent##STR>;

#define DEF_LIST_MARSHALLER(ListIdent,ItemList,Item) /*namespace {*/ char ListIdent##STR[] = #Item; /*}*/  \
        Marshall::HandlerFn marshall_##ListIdent = marshall_ItemList<Item,ItemList,ListIdent##STR>;

#define DEF_VALUELIST_MARSHALLER(ListIdent,ItemList,Item) /*namespace {*/ char ListIdent##STR[] = #Item; /*}*/  \
        Marshall::HandlerFn marshall_##ListIdent = marshall_ValueListItem<Item,ItemList,ListIdent##STR>;

#define DEF_LINKED_LIST_MARSHALLER(ListIdent,ItemList,Item) namespace { char ListIdent##STR[] = #Item; }  \
        Marshall::HandlerFn marshall_##ListIdent = marshall_LinkedItemList<Item,ItemList,ListIdent##STR>;

#define DEF_LINKED_VALUELIST_MARSHALLER(ListIdent,ItemList,Item) namespace { char ListIdent##STR[] = #Item; }  \
        Marshall::HandlerFn marshall_##ListIdent = marshall_LinkedValueListItem<Item,ItemList,ListIdent##STR>;

template <class Item, class ItemList, const char *ItemSTR >
void marshall_ItemList(Marshall *m) {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !listref || !SvROK( listref ) || SvTYPE( SvRV(listref) ) != SVt_PVAV ) {
                m->item().s_voidp = 0;
                break;
            }

            AV *list = (AV*)SvRV(listref);
            int count = av_len(list) + 1;
            ItemList *cpplist = new ItemList;
            for( long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                // TODO do type checking!
                if(!item || !SvOK(*item))
                    continue;
                smokeperl_object *o = sv_obj_info(*item);
                if(!o || !o->ptr)
                    continue;
                void *ptr = o->ptr;
                ptr = o->smoke->cast(
                    ptr,                // pointer
                    o->classId,                // from
                    o->smoke->idClass(ItemSTR).index    // to
                );
                cpplist->append((Item*)ptr);
            }

            m->item().s_voidp = cpplist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);
    
                for(int i = 0; i < cpplist->size(); ++i ) {
                    SV *obj = getPointerObject( (void *) cpplist->at(i) );
                    if( obj )
                        av_push(list, obj);
                    else
                        av_push(list, &PL_sv_undef);
                }
            }

            if (m->cleanup()) {
                delete cpplist;
            }
        }
        break;
      
        case Marshall::ToSV: {
            ItemList * cpplist = (ItemList*)m->item().s_voidp;
            if(cpplist == 0) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV* av = newAV();
            SV* avref = newRV_noinc((SV*)av);

            Smoke::ModuleIndex mi = Smoke::findClass(ItemSTR);

            for (int i=0; i < cpplist->size(); ++i) {
                void *p = (void *) cpplist->at(i);

                if (m->item().s_voidp == 0) {
                    sv_setsv(m->var(), &PL_sv_undef);
                    break;
                }

                SV* obj = getPointerObject(p);
                if (!obj || !SvOK(obj) ) {
                    smokeperl_object *o = alloc_smokeperl_object(
                        false, mi.smoke, mi.index, p );

                    const char* classname = perlqt_modules[o->smoke].resolve_classname(o);

                    obj = set_obj_info( classname, o );
                }
                else {
                    // There's this weird problem where if we just return obj,
                    // if the user then calls something like shift on the array
                    // returned, the refcount of obj goes to 0, and the value
                    // in Qt::_internal::pointer_map gets corrupted.  We can't
                    // just call SvREFCNT_inc on obj either, because I was
                    // seeing that the refcount of the values in the
                    // pointer_map were not getting decremented, even after the
                    // array returned here goes out of scope.  So we return a
                    // new reference.
                    obj = newRV_inc(SvRV(obj));
                }
            
                av_push(av, obj);
            }

            sv_setsv(m->var(), avref);
            m->next();

            if (!m->type().isConst()) {
                int count = av_len(av) + 1;
                long i;
                cpplist->clear();
                for (i = 0; i < count; ++i) {
                    SV** itemref = av_fetch(av, i, 0);
                    if( !itemref )
                        continue;
                    SV* item = *itemref;
                    // TODO do type checking!
                    smokeperl_object *o = sv_obj_info(item);
                    if(!o || !o->ptr)
                        continue;
                    void *ptr = o->ptr;
                    ptr = o->smoke->cast(
                            ptr,				// pointer
                            o->classId,				// from
                            o->smoke->idClass(ItemSTR, true).index	// to
                            );

                    cpplist->append((Item*)ptr);
                }
            }

            if (m->cleanup()) {
                delete cpplist;
            }
        }
        break;

        default:
            m->unsupported();
        break;
   }
}

template <class Item, class ItemList, const char *ItemSTR >
void marshall_ValueListItem(Marshall *m) {
    switch(m->action()) {
        case Marshall::FromSV: {
            SV *listref = m->var();
            if ( !listref || !SvROK( listref ) || SvTYPE( SvRV(listref) ) != SVt_PVAV ) {
                m->item().s_voidp = 0;
                break;
            }
            AV *list = (AV*)SvRV(listref);
            int count = av_len(list) + 1;
            ItemList *cpplist = new ItemList;
            for(long i = 0; i < count; ++i) {
                SV **item = av_fetch(list, i, 0);
                // TODO do type checking!
                if(!item)
                    continue;
                smokeperl_object *o = sv_obj_info(*item);

                // Special case for the QList<QVariant> type
                if (    qstrcmp(ItemSTR, "QVariant") == 0 &&
                        (!o || !o->ptr || o->classId != o->smoke->idClass("QVariant").index) ) 
                {
                    UNTESTED_HANDLER( "marshall_ValueListItem for QVariant" );
                    // If the value isn't a Qt::Variant, then try and construct
                    // a Qt::Variant from it
                    // XXX How to do this?
                    /*
                    item = rb_funcall(qvariant_class, rb_intern("fromValue"), 1, item);
                    if (item == Qnil) {
                        continue;
                    }
                    o = value_obj_info(item);
                    */
                }

                if (!o || !o->ptr)
                    continue;

                void *ptr = o->ptr;
                ptr = o->smoke->cast(
                        ptr,                // pointer
                        o->classId,                // from
                        o->smoke->idClass(ItemSTR).index            // to
                        );
                cpplist->append(*(Item*)ptr);
            }

            m->item().s_voidp = cpplist;
            m->next();

            if (!m->type().isConst()) {
                av_clear(list);
                for(int i=0; i < cpplist->size(); ++i) {
                    SV *obj = getPointerObject((void*)&(cpplist->at(i)));
                    av_push(list, obj);
                }
            }

            if (m->cleanup()) {
                delete cpplist;
            }
        }
        break;

        case Marshall::ToSV: {
            ItemList *valuelist = (ItemList*)m->item().s_voidp;
            if(!valuelist) {
                sv_setsv(m->var(), &PL_sv_undef);
                break;
            }

            AV* av = newAV();
            SV* avref = newRV_noinc((SV*)av);

			Smoke::ModuleIndex mi = Smoke::findClass(ItemSTR);
			const char * className = perlqt_modules[mi.smoke].binding->className(mi.index);

            for(int i=0; i < valuelist->size(); ++i) {
                void *p = (void *) &(valuelist->at(i));

                if(m->item().s_voidp == 0) {
                    sv_setsv(m->var(), &PL_sv_undef);
                    break;
                }

                SV *obj = getPointerObject(p);
                if( !obj || !SvOK(obj) ) {
                    smokeperl_object *o = alloc_smokeperl_object(
                        false, mi.smoke, mi.index, p );

                    obj = set_obj_info( className, o );
                }
                else {
                    // See above.
                    obj = newRV_inc(SvRV(obj));
                }

                av_push(av, obj);
            }

            sv_setsv(m->var(), avref);
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }

        }
        break;

        default:
            m->unsupported();
        break;
    }
}

/*
---*
    The code for the QLinkedList marshallers is identical to the QList and QVector marshallers apart
    from the use of iterators instead of at(), and so it really should be possible to code one marshaller
    to work with all three types.
---*

// These guys don't seem to be used at all in QtRuby.  wtf.

template <class Item, class ItemList, const char *ItemSTR >
void marshall_LinkedItemList(Marshall *m) {
    UNTESTED_HANDLER( "marshall_LinkedItemList" );
    switch(m->action()) {
        case Marshall::FromVALUE:
        {
            VALUE list = *(m->var());
            if (TYPE(list) != T_ARRAY) {
                m->item().s_voidp = 0;
                break;
            }

            int count = RARRAY(list)->len;
            ItemList *cpplist = new ItemList;
            long i;
            for (i = 0; i < count; ++i) {
                VALUE item = rb_ary_entry(list, i);
                // TODO do type checking!
                smokeruby_object *o = value_obj_info(item);
                if (o == 0 || o->ptr == 0)
                    continue;
                void *ptr = o->ptr;
                ptr = o->smoke->cast(
                    ptr,                // pointer
                    o->classId,                // from
                    o->smoke->idClass(ItemSTR).index    // to
                );
                cpplist->append((Item*)ptr);
            }

            m->item().s_voidp = cpplist;
            m->next();

            if (!m->type().isConst()) {
                rb_ary_clear(list);

                QLinkedListIterator<Item*> iter(*cpplist);
                while (iter.hasNext()) {
                    VALUE obj = getPointerObject((void *) iter.next());
                    rb_ary_push(list, obj);
                }    
            }

            if (m->cleanup()) {
                delete cpplist;
            }
        }
        break;
      
        case Marshall::ToVALUE:
        {
            ItemList *valuelist = (ItemList*)m->item().s_voidp;
            if (valuelist == 0) {
                *(m->var()) = Qnil;
                break;
            }

            VALUE av = rb_ary_new();

            QLinkedListIterator<Item*> iter(*valuelist);
            while (iter.hasNext()) {
                void * p = (void *) iter.next();

                if (m->item().s_voidp == 0) {
                    *(m->var()) = Qnil;
                    break;
                }

                VALUE obj = getPointerObject(p);
                if (obj == Qnil) {
                    smokeruby_object  * o = alloc_smokeruby_object(    false, 
                                                                    m->smoke(), 
                                                                    m->smoke()->idClass(ItemSTR).index, 
                                                                    p );

                    const char* classname = perlqt_modules[o->smoke].resolve_classname(o);
                    obj = set_obj_info(classname, o);
                }
            
                rb_ary_push(av, obj);
            }

            *(m->var()) = av;
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }
        }
        break;

        default:
            m->unsupported();
        break;
   }
}

template <class Item, class ItemList, const char *ItemSTR >
void marshall_LinkedValueListItem(Marshall *m) {
    UNTESTED_HANDLER( "marshall_LinkedValueListItem" );
    switch(m->action()) {
        case Marshall::FromVALUE:
        {
            VALUE list = *(m->var());
            if (TYPE(list) != T_ARRAY) {
                m->item().s_voidp = 0;
                break;
            }
            int count = RARRAY(list)->len;
            ItemList *cpplist = new ItemList;
            long i;
            for(i = 0; i < count; ++i) {
                VALUE item = rb_ary_entry(list, i);
                // TODO do type checking!
                smokeruby_object *o = value_obj_info(item);

                // Special case for the QList<QVariant> type
                if (    qstrcmp(ItemSTR, "QVariant") == 0 
                        && (o == 0 || o->ptr == 0 || o->classId != o->smoke->idClass("QVariant").index) ) 
                {
                    // If the value isn't a Qt::Variant, then try and construct
                    // a Qt::Variant from it
                    item = rb_funcall(qvariant_class, rb_intern("fromValue"), 1, item);
                    if (item == Qnil) {
                        continue;
                    }
                    o = value_obj_info(item);
                }

                if (o == 0 || o->ptr == 0)
                    continue;
                
                void *ptr = o->ptr;
                ptr = o->smoke->cast(
                    ptr,                // pointer
                    o->classId,                // from
                    o->smoke->idClass(ItemSTR).index            // to
                );
                cpplist->append(*(Item*)ptr);
            }

            m->item().s_voidp = cpplist;
            m->next();

            if (!m->type().isConst()) {
                rb_ary_clear(list);

                QLinkedListIterator<Item> iter(*cpplist);
                while (iter.hasNext()) {
                    VALUE obj = getPointerObject((void*)&(iter.next()));
                    rb_ary_push(list, obj);
                }
            }

            if (m->cleanup()) {
                delete cpplist;
            }
        }
        break;
      
        case Marshall::ToVALUE:
        {
            ItemList *valuelist = (ItemList*)m->item().s_voidp;
            if (valuelist == 0) {
                *(m->var()) = Qnil;
                break;
            }

            VALUE av = rb_ary_new();

            int ix = m->smoke()->idClass(ItemSTR).index;
            const char * className = qtruby_modules[m->smoke()].binding->className(ix);

            QLinkedListIterator<Item> iter(*valuelist);
            while (iter.hasNext()) {
                void * p = (void*) &(iter.next());

                if(m->item().s_voidp == 0) {
                    *(m->var()) = Qnil;
                    break;
                }

                VALUE obj = getPointerObject(p);
                if(obj == Qnil) {
                    smokeruby_object  * o = alloc_smokeruby_object(    false, 
                                                                    m->smoke(), 
                                                                    m->smoke()->idClass(ItemSTR).index, 
                                                                    p );
                    obj = set_obj_info(className, o);
                }
        
                rb_ary_push(av, obj);
            }

            *(m->var()) = av;
            m->next();

            if (m->cleanup()) {
                delete valuelist;
            }

        }
        break;
      
        default:
            m->unsupported();
        break;
    }
}

template <class Value, const char *ValueSTR >
void marshall_Hash(Marshall *m) {
    UNTESTED_HANDLER( "marshall_Hash" );
    switch(m->action()) {
    case Marshall::FromVALUE:
    {
        VALUE hv = *(m->var());
        if (TYPE(hv) != T_HASH) {
            m->item().s_voidp = 0;
            break;
        }
        
        QHash<QString, Value*> * hash = new QHash<QString, Value*>;
        
        // Convert the ruby hash to an array of key/value arrays
        VALUE temp = rb_funcall(hv, rb_intern("to_a"), 0);

        for (long i = 0; i < RARRAY(temp)->len; ++i) {
            VALUE key = rb_ary_entry(rb_ary_entry(temp, i), 0);
            VALUE value = rb_ary_entry(rb_ary_entry(temp, i), 1);
            
            smokeruby_object *o = value_obj_info(value);
            if( !o || !o->ptr)
                continue;
            void * val_ptr = o->ptr;
            val_ptr = o->smoke->cast(val_ptr, o->classId, o->smoke->idClass(ValueSTR).index);
            
            (*hash)[QString(StringValuePtr(key))] = (Value*)val_ptr;
        }
        
        m->item().s_voidp = hash;
        m->next();
        
        if (m->cleanup())
            delete hash;
    }
    break;
    case Marshall::ToVALUE:
    {
        QHash<QString, Value*> *hash = (QHash<QString, Value*>*) m->item().s_voidp;
        if (hash == 0) {
            *(m->var()) = Qnil;
            break;
        }
        
        VALUE hv = rb_hash_new();
        
        int val_ix = m->smoke()->idClass(ValueSTR).index;
        const char * val_className = qtruby_modules[m->smoke()].binding->className(val_ix);
            
        for (QHashIterator<QString, Value*> it(*hash); it.hasNext(); it.next()) {
            void *val_p = it.value();
            VALUE value_obj = getPointerObject(val_p);
                
            if (value_obj == Qnil) {
                smokeruby_object *o = ALLOC(smokeruby_object);
                o->classId = m->smoke()->idClass(ValueSTR).index;
                o->smoke = m->smoke();
                o->ptr = val_p;
                o->allocated = true;
                value_obj = set_obj_info(val_className, o);
            }
            rb_hash_aset(hv, rb_str_new2(((QString*)&(it.key()))->toLatin1()), value_obj);
        }
        
        *(m->var()) = hv;
        m->next();
        
        if (m->cleanup())
            delete hash;
    }
    break;
      default:
    m->unsupported();
    break;
    }
}
*/

#endif
