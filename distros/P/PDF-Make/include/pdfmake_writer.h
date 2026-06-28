/*
 * libpdfmake — object serializer.
 *
 * Emits any pdfmake_obj_t tree as correct PDF syntax per §7.3.
 * Pure, deterministic, byte-exact. No indirect object numbering or
 * file layout — just "given this object, produce its serial form."
 */

#ifndef PDFMAKE_WRITER_H
#define PDFMAKE_WRITER_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include "pdfmake_crypt.h"

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Object serialization
 *--------------------------------------------------------------------------*/

/* Write any PDF object to the buffer. Dispatches to per-kind writers.
 * Requires arena for name lookup. Returns PDFMAKE_OK or error. */
pdfmake_err_t pdfmake_write_obj(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                const pdfmake_obj_t *obj);

/* Like pdfmake_write_obj but applies per-object encryption.  `crypt` may be
 * NULL (equivalent to pdfmake_write_obj).  `obj_num` is the indirect
 * object's number (used in the per-object key derivation).  When
 * `skip_encrypt` is non-zero, strings and streams inside this obj are
 * emitted plaintext — required for the /Encrypt dict itself. */
pdfmake_err_t pdfmake_write_obj_encrypted(pdfmake_buf_t *buf,
                                          pdfmake_arena_t *arena,
                                          const pdfmake_crypt_ctx_t *crypt,
                                          uint32_t obj_num,
                                          int skip_encrypt,
                                          const pdfmake_obj_t *obj);

/*----------------------------------------------------------------------------
 * Per-kind writers (for direct use when type is known)
 *--------------------------------------------------------------------------*/

/* Write "null" */
pdfmake_err_t pdfmake_write_null(pdfmake_buf_t *buf);

/* Write "true" or "false" */
pdfmake_err_t pdfmake_write_bool(pdfmake_buf_t *buf, int value);

/* Write integer (no decimal point). Locale-independent. */
pdfmake_err_t pdfmake_write_int(pdfmake_buf_t *buf, int64_t value);

/* Write real number. Minimal-length, round-trippable, locale-independent.
 * Integers print without decimal; fractional values use minimal digits. */
pdfmake_err_t pdfmake_write_real(pdfmake_buf_t *buf, double value);

/* Write PDF name with proper escaping (§7.3.5).
 * Escapes #, /, and bytes outside 0x21-0x7E as #XX. */
pdfmake_err_t pdfmake_write_name(pdfmake_buf_t *buf, const char *bytes, size_t len);

/* Write PDF name from interned id. */
pdfmake_err_t pdfmake_write_name_id(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                    uint32_t name_id);

/* Write literal string with proper escaping (§7.3.4.2).
 * Escapes \n \r \t \b \f \( \) \\ */
pdfmake_err_t pdfmake_write_string(pdfmake_buf_t *buf, const uint8_t *bytes, size_t len);

/* Write hex string <AABBCC...> (§7.3.4.3). Uppercase hex, even length. */
pdfmake_err_t pdfmake_write_hexstring(pdfmake_buf_t *buf, const uint8_t *bytes, size_t len);

/* Write array [ obj1 obj2 ... ] */
pdfmake_err_t pdfmake_write_array(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                  const pdfmake_array_t *arr);

/* Write dictionary << /Key1 value1 /Key2 value2 ... >> */
pdfmake_err_t pdfmake_write_dict(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                 const pdfmake_dict_t *dict);

/* Write indirect reference "N G R" */
pdfmake_err_t pdfmake_write_ref(pdfmake_buf_t *buf, uint32_t num, uint16_t gen);

/* Write stream: <<dict>>\nstream\n<raw bytes>\nendstream
 * Note: Sets /Length in dict if not present. */
pdfmake_err_t pdfmake_write_stream(pdfmake_buf_t *buf, pdfmake_arena_t *arena,
                                   const pdfmake_stream_t *stream);

/*----------------------------------------------------------------------------
 * Number formatting helpers
 *--------------------------------------------------------------------------*/

/* Format integer to buffer. Returns bytes written. buf must have at least 21 bytes. */
int pdfmake_format_int(char *buf, int64_t value);

/* Format real to buffer with minimal digits. Returns bytes written.
 * buf must have at least 32 bytes. Locale-independent. */
int pdfmake_format_real(char *buf, double value);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_WRITER_H */
