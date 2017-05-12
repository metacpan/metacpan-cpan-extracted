// OpenSP.xs -- OpenSP XS Wrapper
//
// $Id: OpenSP.xs,v 1.30 2007/12/06 05:58:10 hoehrmann Exp $

// workaround for broken math.h in VC++ 6.0
#if defined(_MSC_VER) && _MSC_VER < 1300
#include <math.h>
#endif

#define PERL_NO_GET_CONTEXT

#define SPO_SMALL_STRINGS_LENGTH 1024

extern "C"
{
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

// these are specific to the system and might need to
// be changed before the Perl extension can compile
#ifdef WIN32
#include <generic/ParserEventGeneratorKit.h>
#else
#include <OpenSP/ParserEventGeneratorKit.h>
#endif

///////////////////////////////////////////////////////////////////////////
// Class SgmlParserOpenSP
///////////////////////////////////////////////////////////////////////////

class SgmlParserOpenSP : private SGMLApplication {
public:
    // ...
    SgmlParserOpenSP();

public:
    // ...
    void parse(SV* file_sv);
    SV*  get_location();
    void halt();

    // ...
    SV*  m_self;

private:
    // OpenSP event handler
    void appinfo               (const AppinfoEvent&               e);
    void pi                    (const PiEvent&                    e);
    void startElement          (const StartElementEvent&          e);
    void endElement            (const EndElementEvent&            e);
    void data                  (const DataEvent&                  e);
    void sdata                 (const SdataEvent&                 e);
    void externalDataEntityRef (const ExternalDataEntityRefEvent& e);
    void subdocEntityRef       (const SubdocEntityRefEvent&       e);
    void startDtd              (const StartDtdEvent&              e);
    void endDtd                (const EndDtdEvent&                e);
    void endProlog             (const EndPrologEvent&             e);
    void generalEntity         (const GeneralEntityEvent&         e);
    void commentDecl           (const CommentDeclEvent&           e);
    void markedSectionStart    (const MarkedSectionStartEvent&    e);
    void markedSectionEnd      (const MarkedSectionEndEvent&      e);
    void ignoredChars          (const IgnoredCharsEvent&          e);
    void error                 (const ErrorEvent&                 e);

    // OpenSP entity change handler
    void openEntityChange      (const OpenEntityPtr&              p);

    // ...
    void dispatchEvent         (const char*                       name,
                                const HV* hv);
    bool handler_can           (const char*                       method);

    // ...
    SV* cs2sv                  (const SGMLApplication::CharString s);
    HV* location2hv            (const SGMLApplication::Location   l);
    HV* notation2hv            (const SGMLApplication::Notation   n);
    HV* externalid2hv          (const SGMLApplication::ExternalId id);
    HV* entity2hv              (const SGMLApplication::Entity     e);
    HV* attributes2hv          (const SGMLApplication::Attribute* attrs,
                                const size_t                      n);
    HV* attribute2hv           (const SGMLApplication::Attribute  a);

    // ...
    bool _hv_fetch_SvTRUE(HV* hv, const char* key, const I32 klen);
    void _hv_fetch_pk_setOption(HV* hv, const char* key, const I32 klen,
                                ParserEventGeneratorKit& pk,
                                const enum ParserEventGeneratorKit::OptionWithArg o);

    // ...
    SV*                            m_handler;
    bool                           m_parsing;
    SGMLApplication::Position      m_pos;
    SGMLApplication::OpenEntityPtr m_openEntityPtr;
    EventGenerator*                m_egp;

    // ...
    PerlInterpreter*               my_perl;

    // ...
    U8 m_temp[SPO_SMALL_STRINGS_LENGTH * UTF8_MAXLEN + 1];
};

///////////////////////////////////////////////////////////////////////////
// computed hash values
///////////////////////////////////////////////////////////////////////////

static U32 HvvAttributes;
static U32 HvvByteOffset;
static U32 HvvCdataChunks;
static U32 HvvColumnNumber;
static U32 HvvComment;
static U32 HvvComments;
static U32 HvvContentType;
static U32 HvvData;
static U32 HvvDataType;
static U32 HvvDeclType;
static U32 HvvDefaulted;
static U32 HvvEntities;
static U32 HvvEntity;
static U32 HvvEntityName;
static U32 HvvEntityOffset;
static U32 HvvExternalId;
static U32 HvvFileName;
static U32 HvvGeneratedSystemId;
static U32 HvvIncluded;
static U32 HvvIndex;
static U32 HvvIsGroup;
static U32 HvvIsId;
static U32 HvvIsInternal;
static U32 HvvIsNonSgml;
static U32 HvvIsSdata;
static U32 HvvLineNumber;
static U32 HvvMessage;
static U32 HvvName;
static U32 HvvNonSgmlChar;
static U32 HvvNone;
static U32 HvvNotation;
static U32 HvvParams;
static U32 HvvPublicId;
static U32 HvvSeparator;
static U32 HvvStatus;
static U32 HvvString;
static U32 HvvSystemId;
static U32 HvvText;
static U32 HvvTokens;
static U32 HvvType;

///////////////////////////////////////////////////////////////////////////
// Helper functions
///////////////////////////////////////////////////////////////////////////

SV* SgmlParserOpenSP::cs2sv(const SGMLApplication::CharString s)
{
    SV* result;
    unsigned int i = 0;
    U8* d;

    // optimized memory-intensive version for small strings
    if (s.len < SPO_SMALL_STRINGS_LENGTH)
    {
        d = m_temp;
        for (i = 0; i < s.len; ++i)
            d = uvuni_to_utf8_flags(d, s.ptr[i], 0);
        result = newSVpvn((const char*)m_temp, d - m_temp);
    }
    else
    {
        result = newSVpvn("", 0);
        for (i = 0; i < s.len; ++i)
        {
            d = (U8 *)SvGROW(result, SvCUR(result) + UTF8_MAXLEN + 1);
            d = uvuni_to_utf8_flags(d + SvCUR(result), s.ptr[i], 0); 
            SvCUR_set(result, d - (U8 *)SvPVX(result));
        }
    }

    SvUTF8_on(result);
    return result;
}

///////////////////////////////////////////////////////////////////////////
// OpenSP data structure conversion helper functions
///////////////////////////////////////////////////////////////////////////

#define uv_or_undef(x) (x == (unsigned long)-1 ? &PL_sv_undef : newSVuv(x))

HV* SgmlParserOpenSP::location2hv(const SGMLApplication::Location l)
{
    HV* hv = newHV();

    hv_store(hv, "LineNumber", 10, uv_or_undef(l.lineNumber), HvvLineNumber);
    hv_store(hv, "ColumnNumber", 12, uv_or_undef(l.columnNumber), HvvColumnNumber);
    hv_store(hv, "ByteOffset", 10, uv_or_undef(l.byteOffset), HvvByteOffset);
    hv_store(hv, "EntityOffset", 12, uv_or_undef(l.entityOffset), HvvEntityOffset);
    hv_store(hv, "EntityName", 10, cs2sv(l.entityName), HvvEntityName);
    hv_store(hv, "FileName", 8, cs2sv(l.filename), HvvFileName);

    return hv;
}

HV* SgmlParserOpenSP::notation2hv(const SGMLApplication::Notation n)
{
    HV* hv = newHV();

    if (n.name.len > 0)
    {
        SV* sv = newRV_noinc((SV*)externalid2hv(n.externalId));
        hv_store(hv, "Name", 4, cs2sv(n.name), HvvName);
        hv_store(hv, "ExternalId", 10, sv, HvvExternalId);
    }

    return hv;
}

HV* SgmlParserOpenSP::externalid2hv(const SGMLApplication::ExternalId id)
{
    HV* hv = newHV();

    if (id.haveSystemId)
        hv_store(hv, "SystemId", 8, cs2sv(id.systemId), HvvSystemId);

    if (id.havePublicId)
        hv_store(hv, "PublicId", 8, cs2sv(id.publicId), HvvPublicId);

    if (id.haveGeneratedSystemId)
    {
        SV* sv = cs2sv(id.generatedSystemId);
        hv_store(hv, "GeneratedSystemId", 17, sv, HvvGeneratedSystemId);
    }

    return hv;
}

HV* SgmlParserOpenSP::entity2hv(const SGMLApplication::Entity e)
{
    HV* hv = newHV();

    hv_store(hv, "Name", 4, cs2sv(e.name), HvvName);

    // dataType
    switch (e.dataType)
    {
    case SGMLApplication::Entity::sgml:
        hv_store(hv, "DataType", 8, newSVpvn("sgml", 4), HvvDataType);
        break;
    case SGMLApplication::Entity::cdata:
        hv_store(hv, "DataType", 8, newSVpvn("cdata", 5), HvvDataType);
        break;
    case SGMLApplication::Entity::sdata:
        hv_store(hv, "DataType", 8, newSVpvn("sdata", 5), HvvDataType);
        break;
    case SGMLApplication::Entity::ndata:
        hv_store(hv, "DataType", 8, newSVpvn("ndata", 5), HvvDataType);
        break;
    case SGMLApplication::Entity::subdoc:
        hv_store(hv, "DataType", 8, newSVpvn("subdoc", 6), HvvDataType);
        break;
    case SGMLApplication::Entity::pi:
        hv_store(hv, "DataType", 8, newSVpvn("pi", 2), HvvDataType);
        break;
    }

    // declType
    switch (e.declType)
    {
    case SGMLApplication::Entity::general:
        hv_store(hv, "DeclType", 8, newSVpvn("general", 7), HvvDeclType);
        break;
    case SGMLApplication::Entity::parameter:
        hv_store(hv, "DeclType", 8, newSVpvn("parameter", 9), HvvDeclType);
        break;
    case SGMLApplication::Entity::doctype:
        hv_store(hv, "DeclType", 8, newSVpvn("doctype", 7), HvvDeclType);
        break;
    case SGMLApplication::Entity::linktype:
        hv_store(hv, "DeclType", 8, newSVpvn("linktype", 8), HvvDeclType);
        break;
    }

    if (e.isInternal)
    {
        hv_store(hv, "IsInternal", 10, newSViv(1), HvvIsInternal);
        hv_store(hv, "Text", 4, cs2sv(e.text), HvvText);
    }
    else
    {
        SV* sv1 = newRV_noinc((SV*)externalid2hv(e.externalId));
        SV* sv2 = newRV_noinc((SV*)attributes2hv(e.attributes, e.nAttributes));
        SV* sv3 = newRV_noinc((SV*)notation2hv(e.notation));
        
        hv_store(hv, "ExternalId", 10, sv1, HvvExternalId);
        hv_store(hv, "Attributes", 10, sv2, HvvAttributes);
        hv_store(hv, "Notation", 8, sv3, HvvNotation);
    }

    return hv;
}

HV* SgmlParserOpenSP::attributes2hv(const SGMLApplication::Attribute* attrs, size_t n)
{
    HV* hv = newHV();

    for (unsigned int i = 0; i < n; ++i)
    {
        HV* a = attribute2hv(attrs[i]);
        hv_store(a, "Index", 5, newSViv(i), HvvIndex);
        hv_store_ent(hv, sv_2mortal(cs2sv(attrs[i].name)), newRV_noinc((SV*)a), 0);
    }

    return hv;
}

HV* SgmlParserOpenSP::attribute2hv(const SGMLApplication::Attribute a)
{
    HV* hv = newHV();

    // Name => ...
    hv_store(hv, "Name", 4, cs2sv(a.name), HvvName);

    // Type => ...
    if (a.type == SGMLApplication::Attribute::cdata)
    {
        AV* av = newAV();

        for (unsigned int i = 0; i < a.nCdataChunks; ++i)
        {
            HV* cc = newHV();

            if (a.cdataChunks[i].isSdata)
            {
                SV* sv = cs2sv(a.cdataChunks[i].entityName);

                // redundant?
                hv_store(cc, "IsSdata", 7, newSViv(1), HvvIsSdata);
                hv_store(cc, "EntityName", 10, sv, HvvEntityName);
            }
            else if (a.cdataChunks[i].isNonSgml)
            {
                SV* sv = newSViv(a.cdataChunks[i].nonSgmlChar);
                
                // redundant?
                hv_store(cc, "IsNonSgml", 9, newSViv(1), HvvIsNonSgml);
                hv_store(cc, "NonSgmlChar", 11, sv, HvvNonSgmlChar);
            }

            hv_store(cc, "Data", 4, cs2sv(a.cdataChunks[i].data), HvvData);

            av_push(av, newRV_noinc((SV*)cc));
        }

        hv_store(hv, "Type", 4, newSVpvn("cdata", 5), HvvType);
        hv_store(hv, "CdataChunks", 11, newRV_noinc((SV*)av), HvvCdataChunks);

    }
    else if (a.type == SGMLApplication::Attribute::tokenized)
    {
        AV* entities = newAV();

        hv_store(hv, "Type", 4, newSVpvn("tokenized", 9), HvvType);
        hv_store(hv, "Tokens", 6, cs2sv(a.tokens), HvvTokens);
        hv_store(hv, "IsGroup", 7, newSViv((int)a.isGroup), HvvIsGroup);
        hv_store(hv, "IsId", 4, newSViv((int)a.isId), HvvIsId);

        for (unsigned int i = 0; i < a.nEntities; ++i)
        {
            av_push(entities, newRV_noinc((SV*)entity2hv(a.entities[i])));
        }

        SV* sv1 = newRV_noinc((SV*)notation2hv(a.notation));
        SV* sv2 = newRV_noinc((SV*)entities);
        
        hv_store(hv, "Notation", 8, sv1, HvvNotation);
        hv_store(hv, "Entities", 8, sv2, HvvEntities);
    }
    else if (a.type == SGMLApplication::Attribute::implied)
    {
        hv_store(hv, "Type", 4, newSVpvn("implied", 7), HvvType);
    }
    else if (a.type == SGMLApplication::Attribute::invalid)
    {
        hv_store(hv, "Type", 4, newSVpvn("invalid", 7), HvvType);
    }

    if (a.type == SGMLApplication::Attribute::cdata ||
        a.type == SGMLApplication::Attribute::tokenized)
    {
        switch (a.defaulted)
        {
        case SGMLApplication::Attribute::specified:
            hv_store(hv, "Defaulted", 9, newSVpvn("specified", 9), HvvDefaulted);
            break;
        case SGMLApplication::Attribute::definition:
            hv_store(hv, "Defaulted", 9, newSVpvn("definition", 10), HvvDefaulted);
            break;
        case SGMLApplication::Attribute::current:
            hv_store(hv, "Defaulted", 9, newSVpvn("current", 7), HvvDefaulted);
            break;
        }
    }

    return hv;
}

///////////////////////////////////////////////////////////////////////////
// ...
///////////////////////////////////////////////////////////////////////////

bool SgmlParserOpenSP::_hv_fetch_SvTRUE(HV* hv, const char* key, const I32 klen)
{
    SV** svp = hv_fetch(hv, key, klen, 0);
    return (svp && SvTRUE(*svp));
}

void SgmlParserOpenSP::_hv_fetch_pk_setOption(HV* hv, const char* key, const I32 klen,
                            ParserEventGeneratorKit& pk,
                            const enum ParserEventGeneratorKit::OptionWithArg o)
{
    SV** svp = hv_fetch(hv, key, klen, 0);
    SV* rv;

    if (!svp || !*svp)
        return;

    // character string
    if (SvPOK(*svp))
    {
        pk.setOption(o, SvPV_nolen(*svp));
        return;
    }

    if (!SvROK(*svp))
        return;

    rv = SvRV(*svp);

    if (!rv)
        return;

    if (!(SvTYPE(rv) == SVt_PVAV))
        return;

    // array reference
    AV* av = (AV*)rv;
    I32 len = av_len(av);

    for (I32 i = 0; i <= len; ++i)
    {
        SV** svp = av_fetch(av, i, 0);

        if (!svp || !*svp || !SvPOK(*svp))
        {
            warn("not a legal argument in %s\n", key);
            continue;
        }

#ifndef SP_WIDE_SYSTEM
        pk.setOption(o, SvPV_nolen(*svp));
#else
        croak("SP_WIDE_SYSTEM is not supported\n");
#endif
    }
}


///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP implementation
///////////////////////////////////////////////////////////////////////////

SgmlParserOpenSP::SgmlParserOpenSP()
{
    dTHX;

    this->my_perl = my_perl;

    // compute hashes to improve performance
    PERL_HASH(HvvAttributes,        "Attributes",        10);
    PERL_HASH(HvvByteOffset,        "ByteOffset",        10);
    PERL_HASH(HvvCdataChunks,       "CdataChunks",       11);
    PERL_HASH(HvvColumnNumber,      "ColumnNumber",      12);
    PERL_HASH(HvvComment,           "Comment",            7);
    PERL_HASH(HvvComments,          "Comments",           8);
    PERL_HASH(HvvContentType,       "ContentType",       11);
    PERL_HASH(HvvData,              "Data",               4);
    PERL_HASH(HvvDataType,          "DataType",           8);
    PERL_HASH(HvvDeclType,          "DeclType",           8);
    PERL_HASH(HvvDefaulted,         "Defaulted",          9);
    PERL_HASH(HvvEntities,          "Entities",           8);
    PERL_HASH(HvvEntity,            "Entity",             6);
    PERL_HASH(HvvEntityName,        "EntityName",        10);
    PERL_HASH(HvvEntityOffset,      "EntityOffset",      12);
    PERL_HASH(HvvExternalId,        "ExternalId",        10);
    PERL_HASH(HvvFileName,          "FileName",           8);
    PERL_HASH(HvvGeneratedSystemId, "GeneratedSystemId", 17);
    PERL_HASH(HvvIncluded,          "Included",           8);
    PERL_HASH(HvvIndex,             "Index",              5);
    PERL_HASH(HvvIsGroup,           "IsGroup",            7);
    PERL_HASH(HvvIsId,              "IsId",               4);
    PERL_HASH(HvvIsInternal,        "IsInternal",        10);
    PERL_HASH(HvvIsNonSgml,         "IsNonSgml",          9);
    PERL_HASH(HvvIsSdata,           "IsSdata",            7);
    PERL_HASH(HvvLineNumber,        "LineNumber",        10);
    PERL_HASH(HvvMessage,           "Message",            7);
    PERL_HASH(HvvName,              "Name",               4);
    PERL_HASH(HvvNonSgmlChar,       "NonSgmlChar",       11);
    PERL_HASH(HvvNone,              "None",               4);
    PERL_HASH(HvvNotation,          "Notation",           8);
    PERL_HASH(HvvParams,            "Params",             6);
    PERL_HASH(HvvPublicId,          "PublicId",           8);
    PERL_HASH(HvvSeparator,         "Separator",          9);
    PERL_HASH(HvvStatus,            "Status",             6);
    PERL_HASH(HvvString,            "String",             6);
    PERL_HASH(HvvSystemId,          "SystemId",           8);
    PERL_HASH(HvvText,              "Text",               4);
    PERL_HASH(HvvTokens,            "Tokens",             6);
    PERL_HASH(HvvType,              "Type",               4);

    // initialize member variables
    m_openEntityPtr = NULL;
    m_parsing       = false;
    m_handler       = NULL;
    m_self          = NULL;
    m_pos           = 0;
    m_egp           = NULL;
}

SV* SgmlParserOpenSP::get_location()
{
    if (!m_parsing)
        croak("get_location() must be called from event handlers\n");

    SGMLApplication::Location l(m_openEntityPtr, m_pos);

    return newRV_noinc((SV*)location2hv(l));
}

void SgmlParserOpenSP::halt()
{
    if (!m_parsing)
        croak("halt() must be called from event handlers\n");

    if (!m_egp)
        croak("egp not available, object corrupted\n");

    m_egp->halt();
}

bool SgmlParserOpenSP::handler_can(const char* method)
{
    if (!method || !m_handler)
        return false;

    if (!SvROK(m_handler) || !sv_isobject(m_handler))
        return false;

    HV* stash = SvSTASH(SvRV(m_handler));

    if (!stash)
        return false;

    // todo: this could benefit from caching the result
    // todo: this does not look for autoloaded methods, should it?
    if (!gv_fetchmethod_autoload(stash, method, FALSE))
        return false;

    return true;
}

void SgmlParserOpenSP::dispatchEvent(const char* name, const HV* hv)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(m_handler);
    XPUSHs(hv ? sv_2mortal(newRV_noinc((SV*)hv)) : &PL_sv_undef);
    PUTBACK;

    // call the callback method; should this use G_KEEPER?
    call_method(name, G_DISCARD | G_SCALAR | G_EVAL);

    // Refetch the stack pointer.
    SPAGAIN;

    // graceful recovery
    if (SvTRUE(ERRSV))
    {
        m_egp->halt();
        POPs;
    }

    PUTBACK;

    FREETMPS;
    LEAVE;
}

void SgmlParserOpenSP::parse(SV* file_sv)
{
    ParserEventGeneratorKit pk;
    HV* hv;
    SV** svp;

    if (!file_sv)
        croak("you must specify a file name\n");
        
    if (!SvPOK(file_sv))
        croak("not a proper file name\n");
        
    if (m_parsing)
        croak("parse must not be called during parse\n");

    if (!m_self || !sv_isobject(m_self))
        croak("not a proper SGML::Parser::OpenSP object\n");

    hv = (HV*)SvRV(m_self);

    svp = hv_fetch(hv, "handler", 7, 0);
    
    if (!svp || !*svp)
        croak("you must specify a handler first\n");
    
    if (!sv_isobject(*svp))
        croak("handler must be a blessed reference\n");
    
    m_handler = *svp;

    // Boolean Options
    if (_hv_fetch_SvTRUE(hv, "show_open_entities", 18))
        pk.setOption(ParserEventGeneratorKit::showOpenEntities);

    if (_hv_fetch_SvTRUE(hv, "show_open_elements", 18))
        pk.setOption(ParserEventGeneratorKit::showOpenElements);

    if (_hv_fetch_SvTRUE(hv, "show_error_numbers", 18))
        pk.setOption(ParserEventGeneratorKit::showErrorNumbers);

    if (_hv_fetch_SvTRUE(hv, "output_comment_decls", 20))
        pk.setOption(ParserEventGeneratorKit::outputCommentDecls);

    if (_hv_fetch_SvTRUE(hv, "output_marked_sections", 22))
        pk.setOption(ParserEventGeneratorKit::outputMarkedSections);

    if (_hv_fetch_SvTRUE(hv, "output_general_entities", 23))
        pk.setOption(ParserEventGeneratorKit::outputGeneralEntities);

    if (_hv_fetch_SvTRUE(hv, "map_catalog_document", 20))
        pk.setOption(ParserEventGeneratorKit::mapCatalogDocument);

    if (_hv_fetch_SvTRUE(hv, "restrict_file_reading", 21))
        pk.setOption(ParserEventGeneratorKit::restrictFileReading);

    // Options with argument
    _hv_fetch_pk_setOption(hv, "warnings", 8, pk,
        ParserEventGeneratorKit::enableWarning);

    _hv_fetch_pk_setOption(hv, "catalogs", 8, pk,
        ParserEventGeneratorKit::addCatalog);

    _hv_fetch_pk_setOption(hv, "search_dirs", 11, pk,
        ParserEventGeneratorKit::addSearchDir);

    _hv_fetch_pk_setOption(hv, "include_params", 14, pk,
        ParserEventGeneratorKit::includeParam);

    _hv_fetch_pk_setOption(hv, "active_links", 12, pk,
        ParserEventGeneratorKit::activateLink);

    char* file = SvPV_nolen(file_sv);

#ifndef SP_WIDE_SYSTEM
    m_egp = pk.makeEventGenerator(1, &file);
#else
    croak("SP_WIDE_SYSTEM is not supported\n");
#endif

    m_egp->inhibitMessages(true);

    m_parsing = true;
    m_egp->run(*this);
    m_parsing = false;

    // all entities closed now
    m_openEntityPtr = NULL;

    delete m_egp;

    // no longer valid
    m_egp = NULL;

    // After graceful recovery croak here to propagate the exception to
    // the caller. I am not sure how useful this behavior actually is,
    // but it's better than silently ignoring the error or to croak
    // before this point as the object would be unusable and leak memory.
    if (SvTRUE(ERRSV))
        croak(Nullch);
}

///////////////////////////////////////////////////////////////////////////
// OpenSP event handler
///////////////////////////////////////////////////////////////////////////

#define updatePosition(pos) m_pos = pos

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::appinfo
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::appinfo(const AppinfoEvent& e)
{
    if (!handler_can("appinfo"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    if (!e.none)
    {
        hv_store(hv, "None", 4, newSViv(0), HvvNone);
        hv_store(hv, "String", 6, cs2sv(e.string), HvvString);
    }
    else
    {
        hv_store(hv, "None", 4, newSViv(1), HvvNone);
    }

    dispatchEvent("appinfo", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::pi
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::pi(const PiEvent& e)
{
    if (!handler_can("processing_instruction"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "EntityName", 10, cs2sv(e.entityName), HvvEntityName);
    hv_store(hv, "Data", 4, cs2sv(e.data), HvvData);
    dispatchEvent("processing_instruction", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::startElement
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::startElement(const StartElementEvent& e)
{
    if (!handler_can("start_element"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();
    SV* sv = newRV_noinc((SV*)attributes2hv(e.attributes, e.nAttributes));

    hv_store(hv, "Name", 4, cs2sv(e.gi), HvvName);
    hv_store(hv, "Attributes", 10, sv, HvvAttributes);

    switch (e.contentType)
    {
    case SGMLApplication::StartElementEvent::empty:
        hv_store(hv, "ContentType", 11, newSVpvn("empty", 5), HvvContentType);
        break;
    case SGMLApplication::StartElementEvent::cdata:
        hv_store(hv, "ContentType", 11, newSVpvn("cdata", 5), HvvContentType);
        break;
    case SGMLApplication::StartElementEvent::rcdata:
        hv_store(hv, "ContentType", 11, newSVpvn("rcdata", 6), HvvContentType);
        break;
    case SGMLApplication::StartElementEvent::mixed:
        hv_store(hv, "ContentType", 11, newSVpvn("mixed", 5), HvvContentType);
        break;
    case SGMLApplication::StartElementEvent::element:
        hv_store(hv, "ContentType", 11, newSVpvn("element", 7), HvvContentType);
        break;
    }

    hv_store(hv, "Included", 8, newSViv(e.included ? 1 : 0), HvvIncluded);

    dispatchEvent("start_element", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::endElement
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::endElement(const EndElementEvent& e)
{
    if (!handler_can("end_element"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "Name", 4, cs2sv(e.gi), HvvName);

    dispatchEvent("end_element", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::data
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::data(const DataEvent& e)
{
    if (!handler_can("data"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "Data", 4, cs2sv(e.data), HvvData);

    dispatchEvent("data", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::sdata
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::sdata(const SdataEvent& e)
{
    if (!handler_can("sdata"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "EntityName", 10, cs2sv(e.entityName), HvvEntityName);
    hv_store(hv, "Text", 4, cs2sv(e.text), HvvText);

    dispatchEvent("sdata", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::externalDataEntityRef
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::externalDataEntityRef(const ExternalDataEntityRefEvent& e)
{
    if (!handler_can("external_data_entity_ref"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "Entity", 6, newRV_noinc((SV*)entity2hv(e.entity)), HvvEntity);

    dispatchEvent("external_data_entity_ref", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::subdocEntityRef
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::subdocEntityRef(const SubdocEntityRefEvent& e)
{
    if (!handler_can("subdoc_entity_ref"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "Entity", 6, newRV_noinc((SV*)entity2hv(e.entity)), HvvEntity);

    dispatchEvent("subdoc_entity_ref", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::startDtd
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::startDtd(const StartDtdEvent& e)
{
    if (!handler_can("start_dtd"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "Name", 4, cs2sv(e.name), HvvName);

    if (e.haveExternalId)
    {
        SV* sv = newRV_noinc((SV*)externalid2hv(e.externalId));
        hv_store(hv, "ExternalId", 10, sv, HvvExternalId);
    }

    dispatchEvent("start_dtd", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::endDtd
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::endDtd(const EndDtdEvent& e)
{
    if (!handler_can("end_dtd"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "Name", 4, cs2sv(e.name), HvvName);

    dispatchEvent("end_dtd", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::endProlog
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::endProlog(const EndPrologEvent& e)
{
    if (!handler_can("end_prolog"))
        return;

    updatePosition(e.pos);

    // ???

    dispatchEvent("end_prolog", NULL);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::generalEntity
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::generalEntity(const GeneralEntityEvent& e)
{
    if (!handler_can("general_entity"))
        return;

    HV* hv = newHV();

    hv_store(hv, "Entity", 6, newRV_noinc((SV*)entity2hv(e.entity)), HvvEntity);

    dispatchEvent("general_entity", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::commentDecl
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::commentDecl(const CommentDeclEvent& e)
{
    if (!handler_can("comment_decl"))
        return;

    updatePosition(e.pos);

    AV* av = newAV();
    HV* hv = newHV();

    for (unsigned int i = 0; i < e.nComments; ++i)
    {
        HV* comment = newHV();
        hv_store(comment, "Comment", 7, cs2sv(e.comments[i]), HvvComment);
        hv_store(comment, "Separator", 9, cs2sv(e.seps[i]), HvvSeparator);
        av_push(av, newRV_noinc((SV*)comment));
    }

    hv_store(hv, "Comments", 8, newRV_noinc((SV*)av), HvvComments);

    dispatchEvent("comment_decl", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::markedSectionStart
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::markedSectionStart(const MarkedSectionStartEvent& e)
{
    if (!handler_can("marked_section_start"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();
    AV* av = newAV();

    switch (e.status)
    {
    case SGMLApplication::MarkedSectionStartEvent::include:
        hv_store(hv, "Status", 6, newSVpvn("include", 7), HvvStatus);
        break;
    case SGMLApplication::MarkedSectionStartEvent::rcdata:
        hv_store(hv, "Status", 6, newSVpvn("rcdata", 6), HvvStatus);
        break;
    case SGMLApplication::MarkedSectionStartEvent::cdata:
        hv_store(hv, "Status", 6, newSVpvn("cdata", 5), HvvStatus);
        break;
    case SGMLApplication::MarkedSectionStartEvent::ignore:
        hv_store(hv, "Status", 6, newSVpvn("ignore", 6), HvvStatus);
        break;
    }

    for (unsigned int i = 0; i < e.nParams; ++i)
    {
        HV* param = newHV();

        switch (e.params[i].type)
        {
        case SGMLApplication::MarkedSectionStartEvent::Param::temp:
            hv_store(param, "Type", 6, newSVpvn("temp", 4), HvvType);
            break;
        case SGMLApplication::MarkedSectionStartEvent::Param::include:
            hv_store(param, "Type", 6, newSVpvn("include", 7), HvvType);
            break;
        case SGMLApplication::MarkedSectionStartEvent::Param::rcdata:
            hv_store(param, "Type", 6, newSVpvn("rcdata", 6), HvvType);
            break;
        case SGMLApplication::MarkedSectionStartEvent::Param::cdata:
            hv_store(param, "Type", 6, newSVpvn("cdata", 5), HvvType);
            break;
        case SGMLApplication::MarkedSectionStartEvent::Param::ignore:
            hv_store(param, "Type", 6, newSVpvn("ignore", 6), HvvType);
            break;
        case SGMLApplication::MarkedSectionStartEvent::Param::entityRef:
            hv_store(param, "Type", 6, newSVpvn("entityRef", 9), HvvType);
            hv_store(param, "EntityName", 10, cs2sv(e.params[i].entityName), HvvEntityName);
            break;
        }

        av_push(av, newRV_noinc((SV*)av));
    }

    hv_store(hv, "Params", 6, newRV_noinc((SV*)av), HvvParams);

    dispatchEvent("marked_section_start", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::markedSectionEnd
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::markedSectionEnd(const MarkedSectionEndEvent& e)
{
    if (!handler_can("marked_section_end"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    switch (e.status)
    {
    case SGMLApplication::MarkedSectionEndEvent::include:
        hv_store(hv, "Status", 6, newSVpvn("include", 7), HvvStatus);
        break;
    case SGMLApplication::MarkedSectionEndEvent::rcdata:
        hv_store(hv, "Status", 6, newSVpvn("rcdata", 6), HvvStatus);
        break;
    case SGMLApplication::MarkedSectionEndEvent::cdata:
        hv_store(hv, "Status", 6, newSVpvn("cdata", 5), HvvStatus);
        break;
    case SGMLApplication::MarkedSectionEndEvent::ignore:
        hv_store(hv, "Status", 6, newSVpvn("ignore", 6), HvvStatus);
        break;
    }

    dispatchEvent("marked_section_end", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::ignoredChars
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::ignoredChars(const IgnoredCharsEvent& e)
{
    if (!handler_can("ignored_chars"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "Data", 4, cs2sv(e.data), HvvData);

    dispatchEvent("ignored_chars", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::error
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::error(const ErrorEvent& e)
{
    if (!handler_can("error"))
        return;

    updatePosition(e.pos);

    HV* hv = newHV();

    hv_store(hv, "Message", 7, cs2sv(e.message), HvvMessage);

    switch (e.type)
    {
    case SGMLApplication::ErrorEvent::quantity:
       hv_store(hv, "Type", 4, newSVpvn("quantity", 8), HvvType);
       break;
    case SGMLApplication::ErrorEvent::idref:
       hv_store(hv, "Type", 4, newSVpvn("idref", 5), HvvType);
       break;
    case SGMLApplication::ErrorEvent::capacity:
       hv_store(hv, "Type", 4, newSVpvn("capacity", 8), HvvType);
       break;
    case SGMLApplication::ErrorEvent::otherError:
       hv_store(hv, "Type", 4, newSVpvn("otherError", 10), HvvType);
       break;
    case SGMLApplication::ErrorEvent::warning:
       hv_store(hv, "Type", 4, newSVpvn("warning", 7), HvvType);
       break;
    case SGMLApplication::ErrorEvent::info:
       hv_store(hv, "Type", 4, newSVpvn("info", 4), HvvType);
       break;
    }

    dispatchEvent("error", hv);
}

///////////////////////////////////////////////////////////////////////////
// SgmlParserOpenSP::openEntityChange
///////////////////////////////////////////////////////////////////////////

void SgmlParserOpenSP::openEntityChange(const OpenEntityPtr& p)
{
    // remember the current open entity
    m_openEntityPtr = p;

    if (handler_can("open_entity_change"))    
        dispatchEvent("open_entity_change", newHV());
}

///////////////////////////////////////////////////////////////////////////
// XS code
///////////////////////////////////////////////////////////////////////////

MODULE = SGML::Parser::OpenSP       PACKAGE = SGML::Parser::OpenSP      

PROTOTYPES: DISABLE

SgmlParserOpenSP*
SgmlParserOpenSP::new()
  INIT:
    SV* os;
    int pfd;
  CODE:
    RETVAL = new SgmlParserOpenSP();
    ST(0) = sv_newmortal();

    sv_upgrade(ST(0), SVt_RV);
    SvRV(ST(0)) = (SV*)newHV();
    SvROK_on(ST(0));
    sv_bless(ST(0), gv_stashpv(CLASS, 1));
    hv_store((HV*)SvRV(ST(0)), "__o", 3, newSViv(PTR2IV(RETVAL)), 0);
  
    os = get_sv("\017", 0);
    pfd = (os && !strEQ("MSWin32", SvPV_nolen(os))) ? 1 : 0;
    hv_store((HV*)SvRV(ST(0)), "pass_file_descriptor", 20, newSViv(pfd), 0);

void
SgmlParserOpenSP::parse(SV* file_sv)

SV*
SgmlParserOpenSP::get_location()

void
SgmlParserOpenSP::halt()

void
SgmlParserOpenSP::DESTROY()
