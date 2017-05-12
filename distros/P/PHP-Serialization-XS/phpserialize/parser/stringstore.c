#include "stringstore.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#define _err(...) do { \
    fprintf(stderr, __VA_ARGS__); \
    fprintf(stderr, "\n"); \
} while (0)

struct stringstate {
    char *data;
};

static const char* _chunker(void *data, unsigned long offset, size_t count)
{
    struct stringstate *state = data;
    return &state->data[offset];
}

int ps_read_string_init(struct ps_parser_state *parser_state, void *userdata)
{
    int rc = 0;

    struct stringstate *state = malloc(sizeof *state);
    state->data = userdata;

    ps_set_userdata(parser_state, state);
    ps_set_chunker(parser_state, _chunker);

    return rc;
}

int ps_read_string_fini(struct ps_parser_state *parser_state)
{
    struct stringstate *state = ps_get_userdata(parser_state);

    if (!state) return -1;
    free(state);

    return 0;
}

/* vim:set ts=4 sw=4 syntax=c.doxygen: */

