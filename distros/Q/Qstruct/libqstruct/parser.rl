#include <inttypes.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>

#include "qstruct/compiler.h"

int calculate_qstruct_packing(struct qstruct_definition *);


%%{
  machine qstruct;
  write data;
}%%

struct qstruct_definition *parse_qstructs(char *schema, size_t schema_size, char *err_buf, size_t err_buf_size) {
  char *p = schema, *pe = schema + schema_size, *eof = 0;
  int cs = -1;

  int curr_line = 1;
  ssize_t i;
  size_t j;
  int err = 0;

  struct qstruct_definition *def = NULL, *new_def, *curr_def, *temp_def;
  struct qstruct_item curr_item;
  ssize_t curr_item_index;
  size_t curr_item_order;
  struct qstruct_definition *def_hash_by_name = NULL, *def_lookup;

  struct qstruct_item *new_items;
  ssize_t items_allocated;
  ssize_t largest_item;
  struct qstruct_item *item_hash_by_name = NULL, *item_lookup;

  char err_ctx_buf[256];
  char err_desc_buf[512];
  char *err_ctx_start, *err_ctx_end;


  // Parsing phase


  // our ragel machine will initialise these variables, assignments here are just to silence compiler warnings
  curr_item_index = 0;
  memset(&curr_item, '\0', sizeof(curr_item));
  items_allocated = 0;
  largest_item = -1;
  curr_item_order = 0;


  #define PARSE_ERROR(...) do { \
    snprintf(err_desc_buf, sizeof(err_desc_buf), __VA_ARGS__); \
    if (!err) err = 1; \
    goto err_bail; \
  } while(0)

  %%{
    action init_qstruct {
      new_def = calloc(sizeof(struct qstruct_definition), 1);
      if (new_def == NULL)
        PARSE_ERROR("out of memory");

      new_def->next = def;
      def = new_def;
      new_def = NULL;

      items_allocated = 64;
      def->items = calloc(items_allocated, sizeof(struct qstruct_item));
      if (def->items == NULL)
        PARSE_ERROR("out of memory");

      largest_item = -1;
      for (i=0; i<items_allocated; i++) def->items[i].occupied = 0;

      curr_item_order = 0;
    }

    action handle_item {
      if (curr_item_index < 0 || curr_item_index > 1000000)
        PARSE_ERROR("@id way out of range");

      if (curr_item_index >= items_allocated) {
        new_items = realloc(def->items, curr_item_index*2 * sizeof(struct qstruct_item));
        if (new_items == NULL) 
          PARSE_ERROR("out of memory");

        def->items = new_items;
        new_items = NULL;

        for(i=items_allocated; i<curr_item_index*2; i++) def->items[i].occupied = 0;
        items_allocated = curr_item_index*2;
      }

      if ((curr_item.type & 0xFFFF) == QSTRUCT_TYPE_BOOL && (curr_item.type & (QSTRUCT_TYPE_MOD_ARRAY_FIX | QSTRUCT_TYPE_MOD_ARRAY_DYN)))
        PARSE_ERROR("bools can't be arrays");

      if ((curr_item.type & 0xFFFF) == QSTRUCT_TYPE_STRING && (curr_item.type & QSTRUCT_TYPE_MOD_ARRAY_FIX))
        PARSE_ERROR("strings can't be fixed-size arrays");

      if ((curr_item.type & 0xFFFF) == QSTRUCT_TYPE_BLOB && (curr_item.type & QSTRUCT_TYPE_MOD_ARRAY_FIX))
        PARSE_ERROR("blobs can't be fixed-size arrays");

      if ((curr_item.type & 0xFFFF) == QSTRUCT_TYPE_NESTED && (curr_item.type & QSTRUCT_TYPE_MOD_ARRAY_FIX))
        PARSE_ERROR("nested qstructs can't be fixed-size arrays");

      if (def->items[curr_item_index].occupied)
        PARSE_ERROR("duplicated index %ld", curr_item_index);

      def->items[curr_item_index].name = curr_item.name;
      def->items[curr_item_index].name_len = curr_item.name_len;
      def->items[curr_item_index].type = curr_item.type;
      def->items[curr_item_index].fixed_array_size = curr_item.fixed_array_size;
      def->items[curr_item_index].nested_name = curr_item.nested_name;
      def->items[curr_item_index].nested_name_len = curr_item.nested_name_len;
      def->items[curr_item_index].occupied = 1;

      if (curr_item_index > largest_item) largest_item = curr_item_index;

      def->items[curr_item_index].item_order = curr_item_order++;
    }

    action handle_qstruct {
      assert(!item_hash_by_name);

      for(i=0; i<=largest_item; i++) {
        if (!def->items[i].occupied)
          PARSE_ERROR("missing item %ld", i);

        HASH_FIND(hh, item_hash_by_name, def->items[i].name, def->items[i].name_len, item_lookup);
        if (item_lookup)
          PARSE_ERROR("duplicate item name '%.*s'", (int) def->items[i].name_len, def->items[i].name);

        HASH_ADD_KEYPTR(hh, item_hash_by_name, def->items[i].name, def->items[i].name_len, &def->items[i]);
      }

      HASH_CLEAR(hh, item_hash_by_name);

      def[0].num_items = largest_item+1;
    }


    newline = '\n' @{ curr_line++; };
    any_count_line = any | newline;
    whitespace_char = any_count_line - 0x21..0x7e;

    alnum_u = alnum | '_';
    lc_alpha_u = [a-z] | '_';
    uc_alpha_u = [A-Z] | '_';
    identifier = lc_alpha_u $!{ PARSE_ERROR("qstruct item names must start with lowercase letters"); }
                 alnum_u*;
    identifier_with_package = uc_alpha_u $!{ PARSE_ERROR("qstruct names must start with uppercase letters"); }
                              alnum_u* ('::' uc_alpha_u alnum_u*)*;
    integer = digit+;

    ws = whitespace_char |
         '#' [^\n]* newline |
         '/*' (any_count_line* - (any_count_line* '*/' any_count_line*)) '*/'
      ;

    type = 'string' %{ curr_item.type = QSTRUCT_TYPE_STRING; } |
           'blob' %{ curr_item.type = QSTRUCT_TYPE_BLOB; } |
           'bool' %{ curr_item.type = QSTRUCT_TYPE_BOOL; } |
           'float' %{ curr_item.type = QSTRUCT_TYPE_FLOAT; } |
           'double' %{ curr_item.type = QSTRUCT_TYPE_DOUBLE; } |
           'int8' %{ curr_item.type = QSTRUCT_TYPE_INT8; } |
           'uint8' %{ curr_item.type = QSTRUCT_TYPE_INT8 | QSTRUCT_TYPE_MOD_UNSIGNED; } |
           'int16' %{ curr_item.type = QSTRUCT_TYPE_INT16; } |
           'uint16' %{ curr_item.type = QSTRUCT_TYPE_INT16 | QSTRUCT_TYPE_MOD_UNSIGNED; } |
           'int32' %{ curr_item.type = QSTRUCT_TYPE_INT32; } |
           'uint32' %{ curr_item.type = QSTRUCT_TYPE_INT32 | QSTRUCT_TYPE_MOD_UNSIGNED; } |
           'int64' %{ curr_item.type = QSTRUCT_TYPE_INT64; } |
           'uint64' %{ curr_item.type = QSTRUCT_TYPE_INT64 | QSTRUCT_TYPE_MOD_UNSIGNED; } |
           identifier_with_package >{ curr_item.nested_name = p; curr_item.type = QSTRUCT_TYPE_NESTED; }
                                   %{ curr_item.nested_name_len = p - curr_item.nested_name; }
      ;

    array_spec = '['
                   ws*
                   integer >{ curr_item.fixed_array_size = 0; }
                           @{ curr_item.fixed_array_size = curr_item.fixed_array_size * 10 + (fc - '0'); }
                   ws*
                 ']' >{ curr_item.type |= QSTRUCT_TYPE_MOD_ARRAY_FIX; }

                  |

                 '[' ws* ']' >{ curr_item.type |= QSTRUCT_TYPE_MOD_ARRAY_DYN; }
      ;

    item = identifier >{ curr_item.name = p; curr_item.fixed_array_size = 1; }
                      %{ curr_item.name_len = p - curr_item.name; }
                      $!{ PARSE_ERROR("invalid identifier"); }
           ws+
           '@' $!{ PARSE_ERROR("expected @ id"); }
           integer >{ curr_item_index = 0; }
                   @{ curr_item_index = curr_item_index * 10 + (fc - '0'); }
           ws+
           type $!{ PARSE_ERROR("unrecognized type"); }
           ws*
           array_spec? $!{ PARSE_ERROR("invalid array specifier"); }
           ws* ';' $!{ PARSE_ERROR("missing semi-colon"); }
      ;

    qstruct = ws*
              ( [qQ] 'struct' ) >init_qstruct
                                $!{ PARSE_ERROR("expected qstruct definition"); }
              ws+
              identifier_with_package >{ def[0].name = p; }
                                      %{ def[0].name_len = p - def[0].name; }
              ws*
             '{'
               ws* (item @handle_item ws*)*
             '}' @handle_qstruct
             (ws* ';')?
      ;

    main := qstruct* ws*;

    write init;
    write exec;
  }%%

  if (cs < qstruct_first_final)
    PARSE_ERROR("general parse error");




  // Compilation phase

  // reverse def list
  for (curr_def = NULL; def;) {
    temp_def = def->next;
    def->next = curr_def;
    curr_def = def;
    def = temp_def;
  }
  def = curr_def;

  assert(!def_hash_by_name);

  for(curr_def = def; curr_def; curr_def = curr_def->next) {
    for(j=0; j<def->num_items; j++) {
      if ((def->items[j].type & 0xFFFF) == QSTRUCT_TYPE_NESTED) {
        HASH_FIND(hh, def_hash_by_name, def->items[j].nested_name, def->items[j].nested_name_len, def_lookup);
        if (!def_lookup)
          PARSE_ERROR("type '%.*s' referred to before being defined", (int) def->items[j].nested_name_len, def->items[j].nested_name);

        def->items[j].nested_def = def_lookup;
      }
    }

    HASH_FIND(hh, def_hash_by_name, curr_def->name, curr_def->name_len, def_lookup);
    if (def_lookup)
      PARSE_ERROR("duplicate def name '%.*s'", (int) curr_def->name_len, curr_def->name);

    HASH_ADD_KEYPTR(hh, def_hash_by_name, curr_def->name, curr_def->name_len, curr_def);

    if (calculate_qstruct_packing(curr_def) < 0)
      PARSE_ERROR("memory error in packing");
  }


  // Success!
  goto cleanup;

  #undef PARSE_ERROR
  err_bail:

  for(err_ctx_start=p; err_ctx_start>schema && *err_ctx_start != '\n' && (p-err_ctx_start) < 20; err_ctx_start--) {}
  while (isspace(*err_ctx_start) && err_ctx_start < p) err_ctx_start++;
  for(err_ctx_end=p; err_ctx_end<(pe-1) && *err_ctx_end != '\n' && (err_ctx_end-p) < 20; err_ctx_end++) {}
  memcpy(err_ctx_buf, err_ctx_start, err_ctx_end - err_ctx_start);
  *(err_ctx_buf + (err_ctx_end - err_ctx_start)) = '\0';
  snprintf(err_buf, err_buf_size, "\n------------------------------------------------------------\nQstruct schema parse error (line %d, character %d)\n\n  %s\n  %*s^\n  %*s|--%s\n\n------------------------------------------------------------\n", curr_line, (int)(p-schema), err_ctx_buf, (int)(p-err_ctx_start), " ", (int)(p-err_ctx_start), " ", err_desc_buf);

  if (def) {
    free_qstruct_definitions(def);
    def = NULL;
  }


  cleanup:

  HASH_CLEAR(hh, item_hash_by_name);
  HASH_CLEAR(hh, def_hash_by_name);

  return def;
}


void free_qstruct_definitions(struct qstruct_definition *def) {
  struct qstruct_definition *temp;

  while (def) {
    if (def->items) free(def->items);
    temp = def->next;
    free(def);
    def = temp;
  }
}
