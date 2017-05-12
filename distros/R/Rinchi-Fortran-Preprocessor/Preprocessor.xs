#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


static SV * startElementHandler = (SV*) NULL;
static SV * endElementHandler = (SV*) NULL;
static SV * characterDataHandler = (SV*) NULL;
static SV * processingInstructionHandler = (SV*) NULL;
static SV * commentHandler = (SV*) NULL;
static SV * startCdataHandler = (SV*) NULL;
static SV * endCdataHandler = (SV*) NULL;
static SV * xmlDeclHandler = (SV*) NULL;

void
call_StartElementHandlerCommon(tag, hasChild)
char * tag;
int hasChild;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(tag, 0)));
    XPUSHs(sv_2mortal(newSViv(hasChild)));
    PUTBACK;

    if(startElementHandler != (SV*) NULL)
        call_sv(startElementHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_StartElementHandlerIdentifier(tag, hasChild, identifier, replaceable)
char * tag;
int hasChild;
char * identifier;
char * replaceable;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(tag, 0)));
    XPUSHs(sv_2mortal(newSViv(hasChild)));
    XPUSHs(sv_2mortal(newSVpv("identifier", 0)));
    XPUSHs(sv_2mortal(newSVpv(identifier, 0)));
    XPUSHs(sv_2mortal(newSVpv("replaceable", 0)));
    XPUSHs(sv_2mortal(newSVpv(replaceable, 0)));
    PUTBACK;

    if(startElementHandler != (SV*) NULL)
        call_sv(startElementHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_StartElementHandlerMacro(tag, hasChild, identifier)
char * tag;
int hasChild;
char * identifier;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(tag, 0)));
    XPUSHs(sv_2mortal(newSViv(hasChild)));
    XPUSHs(sv_2mortal(newSVpv("identifier", 0)));
    XPUSHs(sv_2mortal(newSVpv(identifier, 0)));
    PUTBACK;

    if(startElementHandler != (SV*) NULL)
        call_sv(startElementHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_StartElementHandlerText(tag, hasChild, value)
char * tag;
int hasChild;
char * value;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(tag, 0)));
    XPUSHs(sv_2mortal(newSViv(hasChild)));
    XPUSHs(sv_2mortal(newSVpv("value", 0)));
    XPUSHs(sv_2mortal(newSVpv(value, 0)));
    PUTBACK;

    if(startElementHandler != (SV*) NULL)
        call_sv(startElementHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_StartElementHandlerFile(tag, hasChild, path, lines, guarded, guardId)
char * tag;
int hasChild;
char * path;
int lines;
int guarded;
char * guardId;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(tag, 0)));
    XPUSHs(sv_2mortal(newSViv(hasChild)));
    XPUSHs(sv_2mortal(newSVpv("path", 0)));
    XPUSHs(sv_2mortal(newSVpv(path, 0)));
    XPUSHs(sv_2mortal(newSVpv("lines", 0)));
    XPUSHs(sv_2mortal(newSViv(lines)));
    XPUSHs(sv_2mortal(newSVpv("guarded", 0)));
    if(guarded != 0) {
      XPUSHs(sv_2mortal(newSVpv("yes", 0)));
      if(guardId != NULL) {
        XPUSHs(sv_2mortal(newSVpv("guardId", 0)));
        XPUSHs(sv_2mortal(newSVpv(guardId, 0)));
      }
    } else {
      XPUSHs(sv_2mortal(newSVpv("no", 0)));
    }
    PUTBACK;

    if(startElementHandler != (SV*) NULL)
        call_sv(startElementHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_StartElementHandlerIncludePath(tag, hasChild, path, used)
char * tag;
int hasChild;
char * path;
int used;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(tag, 0)));
    XPUSHs(sv_2mortal(newSViv(hasChild)));
    XPUSHs(sv_2mortal(newSVpv("path", 0)));
    XPUSHs(sv_2mortal(newSVpv(path, 0)));
    XPUSHs(sv_2mortal(newSVpv("used", 0)));
    if(used != 0) {
      XPUSHs(sv_2mortal(newSVpv("yes", 0)));
    } else {
      XPUSHs(sv_2mortal(newSVpv("no", 0)));
    }
    PUTBACK;

    if(startElementHandler != (SV*) NULL)
        call_sv(startElementHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_EndElementHandler(tag)
char * tag;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(tag, 0)));
    PUTBACK;

    if(endElementHandler != (SV*) NULL)
        call_sv(endElementHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_CharacterDataHandler(string)
char * string;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(string, 0)));
    PUTBACK;

    if(characterDataHandler != (SV*) NULL)
        call_sv(characterDataHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_ProcessingInstructionHandler(target,data)
char * target;
char * data;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(target, 0)));
    XPUSHs(sv_2mortal(newSVpv(data, 0)));
    PUTBACK;

    if(processingInstructionHandler != (SV*) NULL)
        call_sv(processingInstructionHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_CommentHandler(string)
char * string;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(string, 0)));
    PUTBACK;

    if(commentHandler != (SV*) NULL)
        call_sv(commentHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
call_StartCdataHandler()
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    PUTBACK;

    if(startCdataHandler != (SV*) NULL)
        call_sv(startCdataHandler, G_DISCARD|G_NOARGS);

    FREETMPS;
    LEAVE;
}


void
call_EndCdataHandler()
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    PUTBACK;

    if(endCdataHandler != (SV*) NULL)
        call_sv(endCdataHandler, G_DISCARD|G_NOARGS);

    FREETMPS;
    LEAVE;
}

void
call_XMLDeclHandler(version, encoding, standalone)
char * version;
char * encoding;
char * standalone;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(version, 0)));
    XPUSHs(sv_2mortal(newSVpv(encoding, 0)));
    XPUSHs(sv_2mortal(newSVpv(standalone, 0)));
    PUTBACK;

    if(xmlDeclHandler != (SV*) NULL)
        call_sv(xmlDeclHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

MODULE = Rinchi::Fortran::Preprocessor		PACKAGE = Rinchi::Fortran::Preprocessor	PREFIX = cppx_		

void
cppx_ProcessFileArg(path, args)
        const char *    path
        SV * args
    INIT:
        I32 argc = -1;
        int n;
        AV * av_args;
        char * arg;
        void malloc_argv(int);
        void parse(const char *);
        void add_argv(char *);

        if (SvROK(args)) {
            av_args = (AV *)SvRV(args);
            if  ((SvTYPE(SvRV(args)) == SVt_PVAV)) {
                argc = av_len(av_args);
                malloc_argv(argc+2);
            }
        }
    CODE:
        for (n = 0; n <= argc; n++) {
             STRLEN l;
             arg = SvPV(*av_fetch(av_args, n, 0), l);
             add_argv(arg);
        }
        parse(path);


void
cppx_ProcessFile(path)
        const char *    path
    CODE:
        {
        void parse(const char *path);
        parse(path);
        }

void
cppx_SetStartElementHandler(name)
        SV *    name
    CODE:
        /* Take a copy of the callback */
        if (startElementHandler == (SV*)NULL) {
            /* First time, so create a new SV */
            startElementHandler = newSVsv(name);
        } else {
            /* Been here before, so overwrite */
            SvSetSV(startElementHandler, name);
        }

void
cppx_SetEndElementHandler(name)
        SV *    name
    CODE:
        /* Take a copy of the callback */
        if (endElementHandler == (SV*)NULL) {
            /* First time, so create a new SV */
            endElementHandler = newSVsv(name);
        } else {
            /* Been here before, so overwrite */
            SvSetSV(endElementHandler, name);
        }

void
cppx_SetCharacterDataHandler(name)
        SV *    name
    CODE:
        /* Take a copy of the callback */
        if (characterDataHandler == (SV*)NULL) {
            /* First time, so create a new SV */
            characterDataHandler = newSVsv(name);
        } else {
            /* Been here before, so overwrite */
            SvSetSV(characterDataHandler, name);
        }


void
cppx_SetProcessingInstructionHandler(name)
        SV *    name
    CODE:
        /* Take a copy of the callback */
        if (processingInstructionHandler == (SV*)NULL) {
            /* First time, so create a new SV */
            processingInstructionHandler = newSVsv(name);
        } else {
            /* Been here before, so overwrite */
            SvSetSV(processingInstructionHandler, name);
        }

void
cppx_SetCommentHandler(name)
        SV *    name
    CODE:
        /* Take a copy of the callback */
        if (commentHandler == (SV*)NULL) {
            /* First time, so create a new SV */
            commentHandler = newSVsv(name);
        } else {
            /* Been here before, so overwrite */
            SvSetSV(commentHandler, name);
        }

void
cppx_SetStartCdataHandler(name)
        SV *    name
    CODE:
        /* Take a copy of the callback */
        if (startCdataHandler == (SV*)NULL) {
            /* First time, so create a new SV */
            startCdataHandler = newSVsv(name);
        } else {
            /* Been here before, so overwrite */
            SvSetSV(startCdataHandler, name);
        }

void
cppx_SetEndCdataHandler(name)
        SV *    name
    CODE:
        /* Take a copy of the callback */
        if (endCdataHandler == (SV*)NULL) {
            /* First time, so create a new SV */
            endCdataHandler = newSVsv(name);
        } else {
            /* Been here before, so overwrite */
            SvSetSV(endCdataHandler, name);
        }

void
cppx_SetXMLDeclHandler(name)
        SV *    name
    CODE:
        /* Take a copy of the callback */
        if (xmlDeclHandler == (SV*)NULL) {
            /* First time, so create a new SV */
            xmlDeclHandler = newSVsv(name);
        } else {
            /* Been here before, so overwrite */
            SvSetSV(xmlDeclHandler, name);
        }


		

