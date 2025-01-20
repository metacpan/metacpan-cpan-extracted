#ifndef PS_PARSER_H_
#define PS_PARSER_H_

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>

extern void (*ps_parser_error_handler)(const char *msg);

struct ps_parser_state;
typedef struct ps_node ps_node;
struct ps_node {
    enum type {
        NODE_ARRAY  = 'a',
        NODE_BOOL   = 'b',
        NODE_INT    = 'i',
        NODE_FLOAT  = 'd',
        NODE_NULL   = 'N',
        NODE_OBJECT = 'O',
        NODE_STRING = 's',
    } type;
    union ps_nodeval {
        struct ps_array {
            long len;
            struct ps_arrayval {
                ps_node *key;
                ps_node *val;
            } *pairs;
            bool is_array;
        } a;
        bool b;
        long double d;
        long long i;
        struct ps_object {
            char *type;
            struct ps_array val;
        } o;
        struct {
            long  len;
            char *val;
        } s;
    } val;
};

typedef int (*ps_dumper_t)(FILE *f, const ps_node *node, int flags);

#define PS_PRINT_PRETTY 1

#define PS_PARSE_FAILURE ((void*)-1)

#ifndef PS_INDENT_SIZE
#define PS_INDENT_SIZE 4
#endif

/**
 * Called to initialize an opaque HoNData parser state.
 *
 * @param state a pointer to a state pointer
 *
 * @return zero on success, non-zero on undifferentiated failure
 */
int ps_init(struct ps_parser_state **state);

/**
 * Called to finalize an opaque HoNData parser state. Frees all internal data
 * associated with the state, but not any data returned by ps_parse().
 *
 * @param state a pointer to a state pointer
 *
 * @return zero on success, non-zero on undifferentiated failure.
 */
int ps_fini(struct ps_parser_state **state);

/** @defgroup getset Getters and setters for state internals */
/** @{ */
void* ps_get_userdata(struct ps_parser_state *state);
int ps_set_userdata(struct ps_parser_state *state, void *data);
/** @} */

/**
 * Parses the set-up store and returns the resulting tree.
 *
 * @param state the parser state
 *
 * @return a @c node or @c PS_PARSE_FAILURE on undifferentiated error
 */
ps_node *ps_parse(struct ps_parser_state *state);

/**
 * Dumps a particular tree or subtree, as YAML, to a file descriptor @p fd.
 *
 * @param f    the stream to which to dump
 * @param node the root of the (sub)tree to dump
 * @param flags OR'ed flags that control the output
 *
 * @return zero on success, non-zero on undifferentiated error
 */
int ps_yaml(FILE *f, const ps_node *node, int flags);

/**
 * Dumps a particular tree or subtree, in the native format, to the file
 * descriptor @p fd.
 *
 * @param f     the stream to which to dump
 * @param node  the root of the (sub)tree to dump
 * @param flags OR'ed flags that control the output
 *
 * @return zero on success, non-zero on undifferentiated error
 */
int ps_dump(FILE *f, const ps_node *node, int flags);

void ps_free(ps_node* ptr);

#endif /* PS_PARSER_H_ */

/* vim:set ts=4 sw=4 syntax=c.doxygen: */

