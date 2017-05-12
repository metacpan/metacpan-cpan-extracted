#include <perl.h>

#include "try-catch-constants.h"
#include "try-catch-parser.h"
#include "try-catch-op.h"

/*** debug ***/

#ifdef TRY_PARSER_DEBUG
    #include <perlio.h>
    #define DEBUG_MSG(fmt...)   PerlIO_printf(PerlIO_stderr(), "TRY_PARSER_DEBUG: " fmt)
#else
    #define DEBUG_MSG(fmt...)
#endif

/*** error reporting ***/
#define syntax_error(msg)   croak("syntax error: %s", msg)

#define lex_buf_ptr         ( PL_parser->bufptr )
#define lex_buf_end         ( PL_parser->bufend )
#define lex_buf_len         ( lex_buf_end - lex_buf_ptr )
#define lex_next_char       ( lex_buf_len > 0 ? lex_buf_ptr[0] : 0 )
#define lex_read(n)         lex_read_to(lex_buf_ptr + (n))

#define parse_char(c)   my_parse_char(aTHX_ c)
static int my_parse_char(pTHX_ const char c) {
    if (lex_next_char != c) {
        return 0;   // different character found
    }

    lex_read(1);
    DEBUG_MSG("char: %c\n", c);
    return 1;
}

#define parse_keyword(keyword)  my_parse_keyword(aTHX_ keyword)
static int my_parse_keyword(pTHX_ char *keyword)
{
    char *b_ptr, *kw_ptr;

    b_ptr = lex_buf_ptr;
    for (kw_ptr = keyword; *kw_ptr; kw_ptr++) {
        if ( (lex_buf_end <= b_ptr) || (*kw_ptr != *b_ptr) ) {
            return 0;   // expected keyword does not match
        }
        b_ptr++;
    }

    if ( (lex_buf_end > b_ptr) && (isWORDCHAR(*b_ptr) || (*b_ptr == ':')) ) {
        return 0;   // there is not end of scanned keyword
    }

    lex_read_to(b_ptr);
    DEBUG_MSG("keyword: %s\n", keyword);
    return 1;
}

#define parse_identifier(allow_ns)  my_parse_identifier(aTHX_ allow_ns)
static SV *my_parse_identifier(pTHX_ int allow_namespace) {
    SV *ident;
    char *end_ptr;

    end_ptr = lex_buf_ptr;
    while (end_ptr < lex_buf_end) {
        if ( (*end_ptr == ':') && allow_namespace
             && (end_ptr+1 < lex_buf_end) && (end_ptr[1] == ':')
        ) {
            // namespace separator "::" in identifier
            end_ptr += 2;
            continue;
        }

        if (!isWORDCHAR(*end_ptr)) {
            break; // end of identifier found
        }
        end_ptr++;
    }

    if (end_ptr == lex_buf_ptr) {
        return 0;   // perl-identifier not found
    }

    ident = newSVpvn(lex_buf_ptr, end_ptr - lex_buf_ptr);
    lex_read_to(end_ptr);
    return ident;
}

#define parse_code_block(inj_code)  my_parse_code_block(aTHX_ inj_code)
static OP *my_parse_code_block(pTHX_ char *inject_code) {
    I32 floor;
    OP *content_op, *ret_op;

    lex_read_space(0);
    if (lex_next_char != '{') {
        return 0;
    }

    lex_read(1);
    // TODO better might be inject OPcode tree - instead of source-code
    if (inject_code) {
        DEBUG_MSG("Inject into block: %s\n", inject_code);
        lex_stuff_pvn(inject_code, strlen(inject_code), 0);
    }
    lex_stuff_pvs("{ local $" MAIN_PKG "::is_end_of_block;", 0);

    floor = start_subparse(0, CVf_ANON);
    content_op = build_block_content_op(parse_block(0));
    ret_op = newANONSUB(floor, NULL, content_op);

    DEBUG_MSG("{ ... }\n");
    lex_read_space(0);
    return ret_op;
}

#define warn_on_unusual_class_name(name)    my_warn_on_unusual_class_name(aTHX_ name)
static void my_warn_on_unusual_class_name(pTHX_ char *name) {
    char *c;

    // do not warn if class-name contains ':' or any upper char
    for (c=name; *c; c++) {
        if ((*c == ':') || isUPPER(*c)) {
            return;
        }
    }

    warn("catch: lower case class-name '%s' may lead to confusion"
         " with perl keywords", name);
}

#define parse_catch_args()  my_parse_catch_args(aTHX)
static OP *my_parse_catch_args(pTHX) {
    SV *class_name_sv, *var_name_sv;
    OP *block_op;
    char *prepend_code = "local $@ = shift;";

    class_name_sv = var_name_sv = NULL;

    lex_read_space(0);
    if (parse_char('(')) {

        // exception class-name
        lex_read_space(0);
        class_name_sv = parse_identifier(1);
        if (class_name_sv) {
            DEBUG_MSG("class-name: %s\n", SvPVbyte_nolen(class_name_sv));
            warn_on_unusual_class_name(SvPVbyte_nolen(class_name_sv));
        }

        // exception variable-name
        lex_read_space(0);
        if (parse_char('$')) {
            var_name_sv = sv_2mortal(parse_identifier(0));
            if (!var_name_sv) {
                syntax_error("invalid catch syntax");
            }
            DEBUG_MSG("varname: %s\n", SvPVbyte_nolen(var_name_sv));
            prepend_code = form("local $@ = my $%s=shift;", SvPVbyte_nolen(var_name_sv));
        }

        lex_read_space(0);
        if (!parse_char(')')) {
            syntax_error("invalid catch syntax");
        }
    }

    block_op = parse_code_block(prepend_code);
    if (!block_op) {
        syntax_error("expected block after 'catch()'");
    }
    return build_catch_args_optree(block_op, class_name_sv);
}

#define parse_all_catch_blocks()    my_parse_all_catch_blocks(aTHX)
static OP *my_parse_all_catch_blocks(pTHX) {
    OP *catch_list_op;

    catch_list_op = NULL;
    while (parse_keyword("catch")) {
        if (!catch_list_op) {
            catch_list_op = newNULLLIST();
        }
        catch_list_op = op_append_elem(OP_LIST,
            catch_list_op,
            newANONLIST( parse_catch_args() )
        );
    }
    return catch_list_op;
}

#define parse_finally_block()   my_parse_finally_block(aTHX)
static OP *my_parse_finally_block(pTHX) {
    OP *finally_block;

    if (!parse_keyword("finally")) {
        return NULL;
    }

    finally_block = parse_code_block(NULL);
    if (!finally_block) {
        syntax_error("expected block after 'finally'");
    }
    return finally_block;
}

static OP *my_parse_try_statement(pTHX)
{
    OP *try_block_op, *catch_list_op, *finally_block_op, *ret_op;

    try_block_op = parse_code_block(NULL);
    if (!try_block_op) {
        syntax_error("expected block after 'try'");
    }

    catch_list_op = parse_all_catch_blocks();
    finally_block_op = parse_finally_block();

    if (!catch_list_op && !finally_block_op) {
        syntax_error("expected catch/finally after try block");
    }

    ret_op = build_statement_optree(
                try_block_op, catch_list_op, finally_block_op);
#ifdef TRY_PARSER_DUMP
    op_dump(ret_op);
#endif
    return ret_op;
}

