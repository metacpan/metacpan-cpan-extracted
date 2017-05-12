/*
 * UUID: 8801bb88-f301-11dc-bf6d-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <string.h>
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

/*
 * Call the start element handler for Common nodes.
 */
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

/*
 * Call the start element handler for Common nodes.
 */
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
    if(strcmp(replaceable,"yes") != 0) {
      XPUSHs(sv_2mortal(newSVpv("replaceable", 0)));
      XPUSHs(sv_2mortal(newSVpv(replaceable, 0)));
    }
    PUTBACK;

    if(startElementHandler != (SV*) NULL)
        call_sv(startElementHandler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

/*
 * Call the start element handler for Macro nodes.
 */
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

/*
 * Call the start element handler for Text nodes.
 */
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

/*
 * Call the start element handler for File nodes.
 */
void
call_StartElementHandlerFile(tag, hasChild, path, lines, guarded, guardId, atime, mtime)
char * tag;
int hasChild;
char * path;
int lines;
int guarded;
char * guardId;
char * atime;
char * mtime;
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(tag, 0)));
    XPUSHs(sv_2mortal(newSViv(hasChild)));
    XPUSHs(sv_2mortal(newSVpv("path", 0)));
    XPUSHs(sv_2mortal(newSVpv(path, 0)));
    XPUSHs(sv_2mortal(newSVpv("accessTime", 0)));
    XPUSHs(sv_2mortal(newSVpv(atime, 0)));
    XPUSHs(sv_2mortal(newSVpv("modifyTime", 0)));
    XPUSHs(sv_2mortal(newSVpv(mtime, 0)));
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

/*
 * Call the start element handler for IncludePath nodes.
 */
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

/*
 * Call the end Element handler.
 */
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

/*
 * Call the Character Data handler.
 */
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

/*
 * Call the Processing Instruction handler.
 */
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

/*
 * Call the character data handler.
 */
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

/*
 * Call the start CDATA handler.
 */
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


/*
 * Call the end CDATA handler.
 */
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

/*
 * Call the XML Declaration handler.
 */
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

MODULE = Rinchi::CPlusPlus::Preprocessor		PACKAGE = Rinchi::CPlusPlus::Preprocessor		PREFIX = cppx_		

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
//* Process the file at the given path with the arguments provided. */
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
//* Process the file at the given path. */
        {
        void parse(const char *path);
        parse(path);
        }

void
cppx_SetStartElementHandler(name)
        SV *    name
    CODE:
//* Set the startElementHandler callback to the supplied method. */
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
//* Set the endElementHandler callback to the supplied method. */
        if (endElementHandler == (SV*)NULL) {
            endElementHandler = newSVsv(name);
        } else {
            SvSetSV(endElementHandler, name);
        }

void
cppx_SetCharacterDataHandler(name)
        SV *    name
    CODE:
//* Set the characterDataHandler callback to the supplied method. */
        if (characterDataHandler == (SV*)NULL) {
            characterDataHandler = newSVsv(name);
        } else {
            SvSetSV(characterDataHandler, name);
        }

void
cppx_SetProcessingInstructionHandler(name)
        SV *    name
    CODE:
//* Set the processingInstructionHandler callback to the supplied method. */
        if (processingInstructionHandler == (SV*)NULL) {
            processingInstructionHandler = newSVsv(name);
        } else {
            SvSetSV(processingInstructionHandler, name);
        }

void
cppx_SetCommentHandler(name)
        SV *    name
    CODE:
//* Set the commentHandler callback to the supplied method. */
        if (commentHandler == (SV*)NULL) {
            commentHandler = newSVsv(name);
        } else {
            SvSetSV(commentHandler, name);
        }

void
cppx_SetStartCdataHandler(name)
        SV *    name
    CODE:
//* Set the startCdataHandler callback to the supplied method. */
        if (startCdataHandler == (SV*)NULL) {
            startCdataHandler = newSVsv(name);
        } else {
            SvSetSV(startCdataHandler, name);
        }

void
cppx_SetEndCdataHandler(name)
        SV *    name
    CODE:
//* Set the endCdataHandler callback to the supplied method. */
        if (endCdataHandler == (SV*)NULL) {
            endCdataHandler = newSVsv(name);
        } else {
            SvSetSV(endCdataHandler, name);
        }

void
cppx_SetXMLDeclHandler(name)
        SV *    name
    CODE:
//* Set the xmlDeclHandler callback to the supplied method. */
        if (xmlDeclHandler == (SV*)NULL) {
            xmlDeclHandler = newSVsv(name);
        } else {
            SvSetSV(xmlDeclHandler, name);
        }


