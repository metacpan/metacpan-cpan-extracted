#ifndef STRINGSTORE_H_
#define STRINGSTORE_H_

#include "ps_parser.h"
#include "ps_parser_store.h"

int ps_read_string_init(struct ps_parser_state *state, void *data);
int ps_read_string_fini(struct ps_parser_state *state);

#endif /* STRINGSTORE_H_ */

