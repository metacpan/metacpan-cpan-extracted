#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdint.h>
#include <stdlib.h>


#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"


#include "qstruct/utils.h"
#include "qstruct/compiler.h"
#include "qstruct/loader.h"
#include "qstruct/builder.h"


typedef struct qstruct_definition * Qstruct_Definitions;
typedef struct qstruct_item * Qstruct_Item;
typedef struct qstruct_builder * Qstruct_Builder;


MODULE = Qstruct         PACKAGE = Qstruct
PROTOTYPES: ENABLE


BOOT:
  PERL_MATH_INT64_LOAD_OR_CROAK;


Qstruct_Definitions
parse_schema(schema_sv)
        SV *schema_sv
    CODE:
        char *schema;
        size_t schema_size;
        struct qstruct_definition *def;
        char err_buf[1024];

        if (!SvPOK(schema_sv)) croak("schema must be a string");
        schema_size = SvCUR(schema_sv);
        schema = SvPV(schema_sv, schema_size);

        def = parse_qstructs(schema, schema_size, err_buf, sizeof(err_buf));

        if (!def) croak("Qstruct::parse error: %s", err_buf);

        RETVAL = def;
    OUTPUT:
        RETVAL


MODULE = Qstruct         PACKAGE = Qstruct::Definitions
PROTOTYPES: ENABLE



void
iterate(def, callback)
        Qstruct_Definitions def
        SV *callback
    CODE:
        HV *def_info, *items_iterator;

        for(; def; def = def->next) {
          ENTER;
          SAVETMPS;

          PUSHMARK(SP);

          def_info = (HV *) sv_2mortal ((SV *) newHV ());
          hv_store(def_info, "def_addr", 8, newSViv((size_t)def), 0);
          hv_store(def_info, "name", 4, newSVpvn(def->name, def->name_len), 0);
          hv_store(def_info, "body_size", 9, newSVnv(def->body_size), 0);
          hv_store(def_info, "num_items", 9, newSVnv(def->num_items), 0);
          XPUSHs(newRV((SV*)def_info));

          PUTBACK;

          call_sv(callback, G_SCALAR);

          FREETMPS;
          LEAVE;
        }


SV *
get_item(def_addr, item_index)
        unsigned long def_addr
        unsigned long item_index
    CODE:
        Qstruct_Definitions def = (Qstruct_Definitions) def_addr; // FIXME: must be better way to do this in XS
        HV * rh;
        struct qstruct_item *item = def->items + item_index;

        rh = (HV *) sv_2mortal ((SV *) newHV ());
        hv_store(rh, "name", 4, newSVpvn(item->name, item->name_len), 0);
        hv_store(rh, "type", 4, newSVnv(item->type), 0);
        hv_store(rh, "fixed_array_size", 16, newSVnv(item->fixed_array_size), 0);
        hv_store(rh, "byte_offset", 11, newSVnv(item->byte_offset), 0);
        hv_store(rh, "bit_offset", 10, newSVnv(item->bit_offset), 0);
        hv_store(rh, "nested_type", 11, newSVpvn(item->nested_name, item->nested_name_len), 0);
        hv_store(rh, "order", 5, newSVnv(item->item_order), 0);

        RETVAL = newRV((SV *)rh);
    OUTPUT:
        RETVAL



void
DESTROY(def)
        Qstruct_Definitions def
    CODE:
        free_qstruct_definitions(def);




MODULE = Qstruct         PACKAGE = Qstruct::Runtime
PROTOTYPES: ENABLE


int
sanity_check(buf_sv)
        SV *buf_sv
    CODE:
        char *buf;
        size_t buf_size;

        if (!SvPOK(buf_sv)) croak("buf is not a string");
        buf_size = SvCUR(buf_sv);
        buf = SvPV(buf_sv, buf_size);

        RETVAL = qstruct_sanity_check(buf, buf_size);
    OUTPUT:
        RETVAL



AV *
unpack_header(buf_sv)
        SV *buf_sv
    CODE:
        char *buf;
        size_t buf_size;
        AV *rv;
        uint64_t magic_id;
        uint32_t body_size, body_count;
        int ret;

        if (!SvPOK(buf_sv)) croak("buf is not a string");
        buf_size = SvCUR(buf_sv);
        buf = SvPV(buf_sv, buf_size);

        if (buf_size > 0) {
          ret = qstruct_unpack_header(buf, buf_size, &magic_id, &body_size, &body_count);
          if (ret) croak("unable to unpack header");
        } else {
          magic_id = body_size = body_count;
        }

        rv = newAV();
        sv_2mortal((SV*)rv);

        av_push(rv, newSViv(0)); // FIXME: magic id
        av_push(rv, newSViv(body_size));
        av_push(rv, newSViv(body_count));

        RETVAL = rv;
    OUTPUT:
        RETVAL



INCLUDE_COMMAND: $^X gen_getters.pl



int
get_bool(buf_sv, body_index, byte_offset, bit_offset)
        SV *buf_sv
        uint32_t body_index
        uint32_t byte_offset
        int bit_offset
    CODE:
        char *buf;
        size_t buf_size;
        int output;
        int ret;

        if (!SvPOK(buf_sv)) croak("buf is not a string");
        buf_size = SvCUR(buf_sv);
        buf = SvPV(buf_sv, buf_size);

        ret = qstruct_get_bool(buf, buf_size, body_index, byte_offset, bit_offset, &output);

        if (ret) croak("malformed qstruct");

        RETVAL = output;
    OUTPUT:
        RETVAL


void
get_string(buf_sv, body_index, byte_offset, output_sv)
        SV *buf_sv
        uint32_t body_index
        uint32_t byte_offset
        SV *output_sv
    CODE:
        char *buf, *output;
        size_t buf_size, output_size;
        int ret;

        if (!SvPOK(buf_sv)) croak("buf is not a string");
        buf_size = SvCUR(buf_sv);
        buf = SvPV(buf_sv, buf_size);

        ret = qstruct_get_pointer(buf, buf_size, body_index, byte_offset, &output, &output_size, 1);

        if (ret) croak("malformed qstruct (%d)", ret);

        SvUPGRADE(output_sv, SVt_PV);

        // Link the reference counts together
        sv_magicext(output_sv, buf_sv, PERL_MAGIC_ext, NULL, NULL, 0);

        SvCUR_set(output_sv, output_size);
        SvPV_set(output_sv, output);
        SvPOK_only(output_sv);

        // Don't try to free this memory: it's owned by buf_sv
        SvLEN_set(output_sv, 0);

        SvREADONLY_on(output_sv);
        SvREADONLY_on(buf_sv);



void
get_raw_bytes(buf_sv, body_index, byte_offset, length, output_sv)
        SV *buf_sv
        uint32_t body_index
        uint32_t byte_offset
        size_t length
        SV *output_sv
    CODE:
        char *buf, *output;
        size_t buf_size, output_size;
        int ret;

        if (!SvPOK(buf_sv)) croak("buf is not a string");
        buf_size = SvCUR(buf_sv);
        buf = SvPV(buf_sv, buf_size);

        ret = qstruct_get_raw_bytes(buf, buf_size, body_index, byte_offset, length, &output, &output_size);
        if (ret) croak("malformed qstruct");

        SvUPGRADE(output_sv, SVt_PV);

        // Link the reference counts together
        sv_magicext(output_sv, buf_sv, PERL_MAGIC_ext, NULL, NULL, 0);

        SvCUR_set(output_sv, output_size);
        SvPV_set(output_sv, output);
        SvPOK_only(output_sv);

        // Don't try to free this memory: it's owned by buf_sv
        SvLEN_set(output_sv, 0);

        SvREADONLY_on(output_sv);
        SvREADONLY_on(buf_sv);



MODULE = Qstruct         PACKAGE = Qstruct::Builder
PROTOTYPES: ENABLE

Qstruct_Builder
new(package, magic_id, body_size, body_count)
        char *package
        uint64_t magic_id
        uint32_t body_size
        uint32_t body_count
    CODE:
        RETVAL = qstruct_builder_new(magic_id, body_size, body_count);
    OUTPUT:
        RETVAL



INCLUDE_COMMAND: $^X gen_setters.pl



void
set_bool(self, body_index, byte_offset, bit_offset, value)
        Qstruct_Builder self
        uint32_t body_index
        uint32_t byte_offset
        int bit_offset
        int value
    CODE:
        if (qstruct_builder_set_bool(self, body_index, byte_offset, bit_offset, value)) croak("out of memory");

void
set_string(self, body_index, byte_offset, value_sv, int alignment)
        Qstruct_Builder self
        uint32_t body_index
        uint32_t byte_offset
        SV *value_sv
    CODE:
        char *value;
        size_t value_size;
        int ret;

        if (!SvPOK(value_sv)) croak("value is not a string");
        value_size = SvCUR(value_sv);
        value = SvPV(value_sv, value_size);

        if (ret = qstruct_builder_set_pointer(self, body_index, byte_offset, value, value_size, alignment, NULL)) croak("out of memory (%d)", ret);


void
set_raw_bytes(self, body_index, byte_offset, bytes)
        Qstruct_Builder self
        uint32_t body_index
        uint32_t byte_offset
        SV *bytes
    CODE:
        size_t bytes_size;
        char *bytesp;

        if (!SvPOK(bytes)) croak("bytes is not a string");
        bytes_size = SvCUR(bytes);
        bytesp = SvPV(bytes, bytes_size);

        if (qstruct_builder_set_raw_bytes(self, body_index, byte_offset, bytesp, bytes_size)) croak("out of memory");



SV *
render(builder)
        Qstruct_Builder builder
    CODE:
        char *msg;
        size_t msg_size;

        msg_size = qstruct_builder_get_msg_size(builder);

        msg = qstruct_builder_get_buf(builder);

        RETVAL = newSVpvn(msg, msg_size);
    OUTPUT:
        RETVAL


void
DESTROY(builder)
        Qstruct_Builder builder
    CODE:
        qstruct_builder_free(builder);
