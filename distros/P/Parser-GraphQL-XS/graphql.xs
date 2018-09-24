#define PERL_NO_GET_CONTEXT      /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "graphqlparser/c/GraphQLParser.h"
#include "graphqlparser/c/GraphQLAstNode.h"
#include "graphqlparser/c/GraphQLAstToJSON.h"

/*
 * This is our internal data structure.
 * We don't really need an object, because the API doesn't actually carry
 * any context from one call to another, so maybe we should get rid of this.
 */
typedef struct GraphQL {
    int unused;
} GraphQL;

/*
 * Helper to parse either a string or a file, with / without schema support.
 */
static SV* graphql_parse(const char* string, const char* file, int schema)
{
    FILE* fp = 0;
    struct GraphQLAstNode* node = 0;
    const char* error = 0;
    const char* json = 0;
    SV* pstr = 0;

    do {
        if (string) {
            node = schema
                 ? graphql_parse_string_with_experimental_schema_support(string, &error)
                 : graphql_parse_string(string, &error);
        }
        else if (file) {
            fp = fopen(file, "r");
            if (!fp) {
                fprintf(stderr, "Could not open file [%s]\n", file);
                break;
            }
            node = schema
                 ? graphql_parse_file_with_experimental_schema_support(fp, &error)
                 : graphql_parse_file(fp, &error);
        }
        else {
            fprintf(stderr, "Need either string of file\n");
            break;
        }

        if (!node) {
            fprintf(stderr, "Parser failed with error [%s]\n", error);
            break;
        }

        json = graphql_ast_to_json(node);
        if (!json) {
            fprintf(stderr, "Could not get JSON\n");
            break;
        }

        pstr = newSVpv(json, 0);
        if (!pstr) {
            fprintf(stderr, "Could not create Perl string\n");
            break;
        }
    } while (0);

    if (json) {
        free((void*) json);
    }
    if (error) {
        graphql_error_free(error);
    }
    if (node) {
        graphql_node_free(node);
    }
    if (fp) {
        fclose(fp);
    }
    return pstr;
}

static GraphQL* graphql_create(void)
{
    GraphQL* graphql = (GraphQL*) malloc(sizeof(GraphQL));
    memset(graphql, 0, sizeof(GraphQL));
    return graphql;
}

static void graphql_destroy(GraphQL* graphql)
{
    free((void*) graphql);
}

static int session_dtor(pTHX_ SV* sv, MAGIC* mg)
{
    (void) sv;
    GraphQL* graphql = (GraphQL*) mg->mg_ptr;
    graphql_destroy(graphql);
    return 0;
}

static MGVTBL session_magic_vtbl = { .svt_free = session_dtor };

MODULE = Parser::GraphQL::XS        PACKAGE = Parser::GraphQL::XS
PROTOTYPES: DISABLE

#################################################################

GraphQL*
new(char* CLASS, HV* opt = NULL)
  CODE:
    RETVAL = graphql_create();
  OUTPUT: RETVAL

SV*
parse_string(GraphQL* graphql, const char* string, int schema = 1)
  CODE:
    RETVAL = graphql_parse(string, 0, schema);
  OUTPUT: RETVAL

SV*
parse_file(GraphQL* graphql, const char* name, int schema = 1)
  CODE:
    RETVAL = graphql_parse(0, name, schema);
  OUTPUT: RETVAL
