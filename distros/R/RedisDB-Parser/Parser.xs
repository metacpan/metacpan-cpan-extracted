/* vim: set expandtab sts=4: */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include "rdb_parser.h"

MODULE = RedisDB::Parser    PACKAGE = RedisDB::Parser::XS    PREFIX = rdb_parser_
PROTOTYPES: DISABLE

RDB_parser*
rdb_parser__new(master, error_class, utf8)
        SV* master;
        SV* error_class;
        int utf8;
    CODE:
        RETVAL = rdb_parser__init(master, error_class, utf8);
        RETVAL->thx = (IV)PERL_GET_THX;
    OUTPUT:
        RETVAL

void
rdb_parser_DESTROY(parser)
        RDB_parser *parser;
    CODE:
        if (parser->thx == (IV)PERL_GET_THX) {
            rdb_parser__free(parser);
        }

SV*
rdb_parser_build_request(parser, ...)
        RDB_parser *parser;
    PREINIT:
        int i;
        STRLEN len;
        char *pv;
        SV *tmp;
    CODE:
        RETVAL = newSV(128);
        sv_setpvf(RETVAL, "*%ld\r\n", items - 1L);
        for (i = 1; i < items; i++) {
            if (parser->utf8) {
                tmp = sv_mortalcopy(ST(i));
                pv  = SvPVutf8(tmp, len);
            }
            else {
                pv = SvPV(ST(i), len);
            }
            sv_catpvf(RETVAL, "$%ld\r\n", (long)len);
            sv_catpvn(RETVAL, pv, len);
            sv_catpvn(RETVAL, "\r\n", 2);
        }
    OUTPUT:
        RETVAL

int
rdb_parser_push_callback(parser, cb)
        RDB_parser *parser;
        SV* cb;
    CODE:
        SvREFCNT_inc(cb);
        av_push(parser->callbacks, cb);
        RETVAL = 1 + av_len(parser->callbacks);
    OUTPUT:
        RETVAL

SV*
rdb_parser_set_default_callback(parser, cb)
        RDB_parser *parser;
        SV* cb;
    CODE:
        if (parser->default_cb != NULL)
            SvSetSV(parser->default_cb, cb);
        else
            parser->default_cb = newSVsv(cb);
        RETVAL = newSVsv(cb);
    OUTPUT:
        RETVAL

void
rdb_parser_callbacks(parser)
        RDB_parser *parser;
    PREINIT:
        int i, len;
        SV **ptr;
    PPCODE:
        len = 1 + av_len(parser->callbacks);
        if (GIMME_V != G_ARRAY) {
            XPUSHs(sv_2mortal(newSViv(len)));
        }
        else {
            EXTEND(SP, len);
            for (i=0; i < len; i++) {
                ptr = av_fetch(parser->callbacks, i, 0);
                if (ptr == NULL) {
                    croak("Callback doesn't exist");
                }
                PUSHs(*ptr);
            }
        }

void
rdb_parser_propagate_reply(parser, reply)
        RDB_parser *parser;
        SV *reply;
    CODE:
        rdb_parser__propagate_reply(parser, reply);

int
rdb_parser_parse(parser, data)
        RDB_parser *parser;
        SV* data;
    CODE:
        sv_catsv(parser->buffer, data);
        RETVAL = 0;
        while (sv_len(parser->buffer) && rdb_parser__parse_reply(parser))
            RETVAL++;
    OUTPUT:
        RETVAL
