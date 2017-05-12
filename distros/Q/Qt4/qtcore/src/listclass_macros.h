#ifndef LISTCLASS_MACROS_H
#define LISTCLASS_MACROS_H

#include <marshall_types.h>

extern QList<Smoke*> smokeList;

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_Vector_at( pTHX_ CV* cv)
{
    dXSARGS;
    if (items != 2)
       Perl_croak(aTHX_ "Usage: %s::at(array, index)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	index = (int)SvIV(ST(1));
        SV *	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;
        if ( 0 > index || index > vector->size() - 1 )
            XSRETURN_UNDEF;

        /*
        QString typeName( typeid(*list->at(index)).name() );
        int pos;
        if ( (pos = typeName.indexOf( "QTestKeyEvent" )) != -1 ) {
            typeName.remove(0, pos);
        }
        else if ( (pos = typeName.indexOf( "QTestKeyClicksEvent" )) != -1 ) {
            typeName.remove(0, pos);
        }
        else if ( (pos = typeName.indexOf( "QTestMouseEvent" )) != -1 ) {
            typeName.remove(0, pos);
        }
        else if ( (pos = typeName.indexOf( "QTestDelayEvent" )) != -1 ) {
            typeName.remove(0, pos);
        }
        typeName.append('*');
        */

        Smoke::StackItem retval[1];
        retval[0].s_voidp = (void*)vector->at(index);
        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
             if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                 typeId.smoke = smoke;
                 break;
             }
        }
        SmokeType type( typeId.smoke, typeId.index );
        PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
        RETVAL = callreturn.var();
        ST(0) = RETVAL;
        // ST(0) is already mortal
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_at( pTHX_ CV* cv)
{
    dXSARGS;
    if (items != 2)
       Perl_croak(aTHX_ "Usage: %s::at(array, index)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	index = (int)SvIV(ST(1));
        SV *	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;
        if ( 0 > index || index > vector->size() - 1 )
            XSRETURN_UNDEF;

        Smoke::StackItem retval[1];
        retval[0].s_voidp = (void*)&vector->at(index);
        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
             if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                 typeId.smoke = smoke;
                 break;
             }
        }
        SmokeType type( typeId.smoke, typeId.index );
        PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
        RETVAL = callreturn.var();
        ST(0) = RETVAL;
        // ST(0) is already mortal
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_exists( pTHX_ CV* cv)
{
    dXSARGS;
    if (items != 2)
        Perl_croak(aTHX_ "Usage: %s::exists(array, index)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	index = (int)SvIV(ST(1));
        bool	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;
        if ( 0 > index || index > vector->size() - 1 )
            RETVAL = false;
        else
            RETVAL = true;
        ST(0) = boolSV(RETVAL);
        sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

template <class ItemVector, const char* PerlName>
void XS_ValueVector_size( pTHX_ CV* cv)
{
    dXSARGS;
    if (items != 1)
        Perl_croak(aTHX_ "Usage: %s::size(array)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	RETVAL;
        dXSTARG;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;
        RETVAL = vector->size();
        XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_store( pTHX_ CV* cv)
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
        ItemVector* vector = (ItemVector*)o->ptr;
        Item* point = (Item*)valueo->ptr;

        if ( 0 > index )
            XSRETURN_UNDEF;

        if ( index >= vector->size() ) {
            while ( index > vector->size() ) {
                vector->append( Item() );
            }
            vector->append( *point );
        }
        else
            vector->replace( index, *point );

        RETVAL = newSVsv(value);
        ST(0) = RETVAL;
        sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_storesize( pTHX_ CV* cv)
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
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        vector->resize( count );
        PUTBACK;
        return;
    }
}

template <class ItemList, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueList_storesize( pTHX_ CV* cv)
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
        ItemList* vector = (ItemList*)o->ptr;

        while ( count > vector->size() )
            vector->append( Item() );
        while ( count < vector->size() )
            vector->removeLast();

        PUTBACK;
        return;
    }
}


template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_delete( pTHX_ CV* cv)
{
    dXSARGS;
        if (items != 2)
            Perl_croak(aTHX_ "Usage: %s::delete(array, index)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	index = (int)SvIV(ST(1));
        SV *	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        Smoke::StackItem retval[1];
        // Must copy, because the replace() below will delete the return value
        // of at().
        retval[0].s_voidp = (void*)new Item(vector->at(index));

        vector->replace( index, Item() );

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
             if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                 typeId.smoke = smoke;
                 break;
             }
        }
        SmokeType type( typeId.smoke, typeId.index );
        PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
        RETVAL = callreturn.var();
        if ( SvTYPE(SvRV(RETVAL)) == SVt_PVAV ) {
            for( int i=0; i < av_len((AV*)SvRV(RETVAL))+1; ++i ) {
                SV* val = *(av_fetch((AV*)SvRV(RETVAL), i, 0));
                sv_obj_info(val)->allocated = true;
            }
        }
        else {
            sv_obj_info(RETVAL)->allocated = true;
        }

        ST(0) = RETVAL;
        sv_2mortal(ST(0));
    }
    XSRETURN(1);
}


template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_clear( pTHX_ CV* cv)
{
    dXSARGS;
        if (items != 1)
            Perl_croak(aTHX_ "Usage: %s::clear(array)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        vector->clear();
    }
    XSRETURN_EMPTY;
}

template <class ItemList, class Item, const char *ItemSTR, const char* PerlName>
void XS_Vector_push( pTHX_ CV* cv)
{
    dXSARGS;
    if (items < 1)
        Perl_croak(aTHX_ "Usage: %s::push(array, ...)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	RETVAL;
        dXSTARG;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemList* list = (ItemList*)o->ptr;

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
            if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                typeId.smoke = smoke;
                break;
            }
        }
        SmokeType type( typeId.smoke, typeId.index );

        for( int i = 1; i < items; ++i ) {
            PerlQt4::MarshallSingleArg marshalledArg( typeId.smoke, ST(i), type );
            Item* point = (Item*)marshalledArg.item().s_voidp;
            list->append( point );
        }
        RETVAL = list->size();
        XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_push( pTHX_ CV* cv)
{
    dXSARGS;
    if (items < 1)
        Perl_croak(aTHX_ "Usage: %s::push(array, ...)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	RETVAL;
        dXSTARG;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
            if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                typeId.smoke = smoke;
                break;
            }
        }
        SmokeType type( typeId.smoke, typeId.index );

        for( int i = 1; i < items; ++i ) {
            PerlQt4::MarshallSingleArg marshalledArg( typeId.smoke, ST(i), type );
            Item* point = (Item*)marshalledArg.item().s_voidp;
            vector->append( *point );
        }
        RETVAL = vector->size();
        XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_pop( pTHX_ CV* cv)
{
    dXSARGS;
        if (items != 1)
            Perl_croak(aTHX_ "Usage: %s::pop(array)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        SV *	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;
        if ( vector->isEmpty() )
            XSRETURN_UNDEF;

        Smoke::StackItem retval[1];
        retval[0].s_voidp = (void*)&vector->last();

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
             if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                 typeId.smoke = smoke;
                 break;
             }
        }
        SmokeType type( typeId.smoke, typeId.index );
        PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
        RETVAL = callreturn.var();

        vector->pop_back();
        ST(0) = RETVAL;
        sv_2mortal(ST(0));
    }
    XSRETURN(1);
}


template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_Vector_shift( pTHX_ CV* cv)
{
    dXSARGS;
        if (items != 1)
            Perl_croak(aTHX_ "Usage: %s::shift(array)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        SV *	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        if ( vector->size() == 0 )
            XSRETURN_UNDEF;

        Smoke::StackItem retval[1];
        retval[0].s_voidp = vector->first();
        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
             if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                 typeId.smoke = smoke;
                 break;
             }
        }
        SmokeType type( typeId.smoke, typeId.index );
        PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
        RETVAL = callreturn.var();
        vector->pop_front();
        ST(0) = RETVAL;
        sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_shift( pTHX_ CV* cv)
{
    dXSARGS;
        if (items != 1)
            Perl_croak(aTHX_ "Usage: %s::shift(array)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        SV *	RETVAL;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        if ( vector->size() == 0 )
            XSRETURN_UNDEF;

        Smoke::StackItem retval[1];
        // Must copy, because the pop_front() below will delete the return value
        // of at().
        retval[0].s_voidp = (void*)new Item(vector->first());
        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
             if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                 typeId.smoke = smoke;
                 break;
             }
        }
        SmokeType type( typeId.smoke, typeId.index );
        PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
        RETVAL = callreturn.var();
        vector->pop_front();
        if ( SvTYPE(SvRV(RETVAL)) == SVt_PVAV ) {
            for( int i=0; i < av_len((AV*)SvRV(RETVAL))+1; ++i ) {
                SV* val = *(av_fetch((AV*)SvRV(RETVAL), i, 0));
                sv_obj_info(val)->allocated = true;
            }
        }
        else {
            sv_obj_info(RETVAL)->allocated = true;
        }
        ST(0) = RETVAL;
        sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_Vector_unshift( pTHX_ CV* cv)
{
    dXSARGS;
        if (items < 1)
            Perl_croak(aTHX_ "Usage: %s::unshift(array, ...)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	RETVAL;
        dXSTARG;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
            if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                typeId.smoke = smoke;
                break;
            }
        }
        SmokeType type( typeId.smoke, typeId.index );

        for( int i = items-1; i >= 1; --i ) {
            PerlQt4::MarshallSingleArg marshalledArg( typeId.smoke, ST(i), type );
            Item* point = (Item*)marshalledArg.item().s_voidp;
            vector->insert( 0, point );
        }
        RETVAL = vector->size();
        XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_unshift( pTHX_ CV* cv)
{
    dXSARGS;
        if (items < 1)
            Perl_croak(aTHX_ "Usage: %s::unshift(array, ...)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	RETVAL;
        dXSTARG;
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
            if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                typeId.smoke = smoke;
                break;
            }
        }
        SmokeType type( typeId.smoke, typeId.index );

        for( int i = items-1; i >= 1; --i ) {
            PerlQt4::MarshallSingleArg marshalledArg( typeId.smoke, ST(i), type );
            Item* point = (Item*)marshalledArg.item().s_voidp;
            vector->insert( 0, *point );
        }
        RETVAL = vector->size();
        XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueVector_splice( pTHX_ CV* cv)
{
    dXSARGS;
        if (items < 1)
            Perl_croak(aTHX_ "Usage: %s::splice(array, firstIndex = 0, length = -1, ...)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	firstIndex;
        int	length;

        if (items < 2)
            firstIndex = 0;
        else {
            firstIndex = (int)SvIV(ST(1));
        }

        if (items < 3)
            length = -1;
        else {
            length = (int)SvIV(ST(2));
        }
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemVector* vector = (ItemVector*)o->ptr;

        if ( firstIndex > vector->size() )
            firstIndex = vector->size();

        if ( length == -1 )
            length = vector->size()-firstIndex;

        int lastIndex = firstIndex + length;

        AV* args = newAV();
        for( int i = 3; i < items; ++i ) {
            av_push(args, ST(i));
        }

        EXTEND(SP, length);

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
            if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                typeId.smoke = smoke;
                break;
            }
        }
        SmokeType type( typeId.smoke, typeId.index );
        Smoke::ModuleIndex mi = Smoke::classMap[ItemSTR];
        for( int i = firstIndex, j = 0; i < lastIndex; ++i, ++j ) {
            Smoke::StackItem retval[1];
            // Must copy, because the remove() below will delete the return value
            // of at().
            retval[0].s_voidp = (void*)new Item(vector->at(firstIndex));
            PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
            
            ST(j) = callreturn.var();
            if ( SvTYPE(SvRV(ST(j))) == SVt_PVAV ) {
                for( int k=0; k < av_len((AV*)SvRV(ST(j)))+1; ++k ) {
                    SV* val = *(av_fetch((AV*)SvRV(ST(j)), k, 0));
                    sv_obj_info(val)->allocated = true;
                }
            }
            else {
                sv_obj_info(ST(j))->allocated = true;
            }
            vector->remove(firstIndex);
        }

        for( int i = items-4; i >= 0; --i ) {
            PerlQt4::MarshallSingleArg marshalledArg( typeId.smoke, av_pop(args), type );
            Item* point = (Item*)marshalledArg.item().s_voidp;
            vector->insert(firstIndex, *point);
        }

        XSRETURN( length );
    }
    XSRETURN(1);
}

template <class ItemList, class Item, const char *ItemSTR, const char* PerlName>
void XS_List_splice( pTHX_ CV* cv)
{
    dXSARGS;
        if (items < 1)
            Perl_croak(aTHX_ "Usage: %s::splice(array, firstIndex = 0, length = -1, ...)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	firstIndex;
        int	length;

        if (items < 2)
            firstIndex = 0;
        else {
            firstIndex = (int)SvIV(ST(1));
        }

        if (items < 3)
            length = -1;
        else {
            length = (int)SvIV(ST(2));
        }
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemList* list = (ItemList*)o->ptr;

        if ( firstIndex > list->size() )
            firstIndex = list->size();

        if ( length == -1 )
            length = list->size()-firstIndex;

        int lastIndex = firstIndex + length;

        AV* args = newAV();
        for( int i = 3; i < items; ++i ) {
            av_push(args, ST(i));
        }

        EXTEND(SP, length);

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
            if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                typeId.smoke = smoke;
                break;
            }
        }
        SmokeType type( typeId.smoke, typeId.index );
        Smoke::ModuleIndex mi = Smoke::classMap[ItemSTR];
        for( int i = firstIndex, j = 0; i < lastIndex; ++i, ++j ) {
            Smoke::StackItem retval[1];
            retval[0].s_voidp = (void*)&list->at(firstIndex); 
            PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
            
            ST(j) = callreturn.var();
            list->removeAt(firstIndex);
        }

        for( int i = items-4; i >= 0; --i ) {
            PerlQt4::MarshallSingleArg marshalledArg( typeId.smoke, av_pop(args), type );
            Item* point = (Item*)marshalledArg.item().s_voidp;
            list->insert(firstIndex, point);
        }

        XSRETURN( length );
    }
    XSRETURN(1);
}

template <class ItemList, class Item, const char *ItemSTR, const char* PerlName>
void XS_ValueList_splice( pTHX_ CV* cv)
{
    dXSARGS;
        if (items < 1)
            Perl_croak(aTHX_ "Usage: %s::splice(array, firstIndex = 0, length = -1, ...)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	array = ST(0);
        int	firstIndex;
        int	length;

        if (items < 2)
            firstIndex = 0;
        else {
            firstIndex = (int)SvIV(ST(1));
        }

        if (items < 3)
            length = -1;
        else {
            length = (int)SvIV(ST(2));
        }
        smokeperl_object* o = sv_obj_info(array);
        if (!o || !o->ptr)
            XSRETURN_UNDEF;
        ItemList* list = (ItemList*)o->ptr;

        if ( firstIndex > list->size() )
            firstIndex = list->size();

        if ( length == -1 )
            length = list->size()-firstIndex;

        int lastIndex = firstIndex + length;

        AV* args = newAV();
        for( int i = 3; i < items; ++i ) {
            av_push(args, ST(i));
        }

        EXTEND(SP, length);

        Smoke::ModuleIndex typeId;
        foreach( Smoke* smoke, smokeList ) {
            if( ( typeId.index = smoke->idType(ItemSTR) ) ) {
                typeId.smoke = smoke;
                break;
            }
        }
        SmokeType type( typeId.smoke, typeId.index );
        Smoke::ModuleIndex mi = Smoke::classMap[ItemSTR];
        for( int i = firstIndex, j = 0; i < lastIndex; ++i, ++j ) {
            Smoke::StackItem retval[1];
            retval[0].s_voidp = (void*)&list->at(firstIndex); 
            PerlQt4::MethodReturnValue callreturn( typeId.smoke, retval, type );
            
            ST(j) = callreturn.var();
            list->removeAt(firstIndex);
        }

        for( int i = items-4; i >= 0; --i ) {
            PerlQt4::MarshallSingleArg marshalledArg( typeId.smoke, av_pop(args), type );
            Item* point = (Item*)marshalledArg.item().s_voidp;
            list->insert(firstIndex, *point);
        }

        XSRETURN( length );
    }
    XSRETURN(1);
}

template <class ItemVector, class Item, const char *ItemSTR, const char* PerlName, const char *ItemVectorSTR>
void XS_ValueVector__overload_op_equality( pTHX_ CV* cv)
{
    dXSARGS;
        if (items != 3)
            Perl_croak(aTHX_ "Usage: %s::operator=(first, second, reversed)", PerlName);
    PERL_UNUSED_VAR(cv); /* -W */
    {
        SV*	first = ST(0);
        SV*	second = ST(1);
        bool	RETVAL;
        smokeperl_object* o1 = sv_obj_info(first);
        if (!o1 || !o1->ptr)
            XSRETURN_UNDEF;
        ItemVector* list1 = (ItemVector*)o1->ptr;

        smokeperl_object* o2 = sv_obj_info(second);
        if (!o2 || !o2->ptr || isDerivedFrom(o2, ItemVectorSTR) == -1)
            XSRETURN_UNDEF;
        ItemVector* list2 = (ItemVector*)o2->ptr;

        RETVAL = *list1 == *list2;
        ST(0) = boolSV(RETVAL);
        sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

#define DEF_VECTORCLASS_FUNCTIONS(ItemVector,Item,PerlName) \
namespace { \
char ItemVector##STR[] = #ItemVector;\
char Item##STR[] = #Item;\
char Item##PerlNameSTR[] = #PerlName;\
void (*XS_##ItemVector##_at)(pTHX_ CV*)                    = XS_ValueVector_at<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_exists)(pTHX_ CV*)                = XS_ValueVector_exists<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_size)(pTHX_ CV*)                  = XS_ValueVector_size<ItemVector, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_store)(pTHX_ CV*)                 = XS_ValueVector_store<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_storesize)(pTHX_ CV*)             = XS_ValueVector_storesize<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_delete)(pTHX_ CV*)                = XS_ValueVector_delete<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_clear)(pTHX_ CV*)                 = XS_ValueVector_clear<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_push)(pTHX_ CV*)                  = XS_ValueVector_push<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_pop)(pTHX_ CV*)                   = XS_ValueVector_pop<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_shift)(pTHX_ CV*)                 = XS_ValueVector_shift<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_unshift)(pTHX_ CV*)               = XS_ValueVector_unshift<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##_splice)(pTHX_ CV*)                = XS_ValueVector_splice<ItemVector, Item, Item##STR, Item##PerlNameSTR>;\
void (*XS_##ItemVector##__overload_op_equality)(pTHX_ CV*) = XS_ValueVector__overload_op_equality<ItemVector, Item, Item##STR, Item##PerlNameSTR, ItemVector##STR>;\
\
}

#define DEF_LISTCLASS_FUNCTIONS(ItemList,Item,ItemName,PerlName) \
namespace { \
char ItemList##STR[] = #ItemList;\
char ItemName##STR[] = #Item;\
char ItemName##PerlNameSTR[] = #PerlName;\
void (*XS_##ItemList##_at)(pTHX_ CV*)                    = XS_ValueVector_at<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_exists)(pTHX_ CV*)                = XS_ValueVector_exists<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_size)(pTHX_ CV*)                  = XS_ValueVector_size<ItemList, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_store)(pTHX_ CV*)                 = XS_ValueVector_store<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_storesize)(pTHX_ CV*)             = XS_ValueList_storesize<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_delete)(pTHX_ CV*)                = XS_ValueVector_delete<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_clear)(pTHX_ CV*)                 = XS_ValueVector_clear<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_push)(pTHX_ CV*)                  = XS_ValueVector_push<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_pop)(pTHX_ CV*)                   = XS_ValueVector_pop<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_shift)(pTHX_ CV*)                 = XS_ValueVector_shift<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_unshift)(pTHX_ CV*)               = XS_ValueVector_unshift<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##_splice)(pTHX_ CV*)                = XS_ValueList_splice<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR>;\
void (*XS_##ItemList##__overload_op_equality)(pTHX_ CV*) = XS_ValueVector__overload_op_equality<ItemList, Item, ItemName##STR, ItemName##PerlNameSTR, ItemList##STR>;\
\
}

#endif
