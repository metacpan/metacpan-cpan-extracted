#ifndef PS_PARSER_INTERNAL_H_
#define PS_PARSER_INTERNAL_H_

#include "ps_parser_store.h"

struct ps_parser_state {
    chunker_t chunker;
    void *userdata;
};

#endif /* PS_PARSER_INTERNAL_H_ */

