#ifndef PDL_IO_ARROW_BRIDGE_H
#define PDL_IO_ARROW_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    char*    name;
    char*    type_name; /* double, float, sbyte, byte, short, ushort, long, ulong, longlong, ulonglong */
    uint8_t* data;
    size_t   data_len;
    int64_t  num_elements;
} PdlArrowColumn;

typedef struct {
    PdlArrowColumn* columns;
    size_t          num_columns;
    char*           error;
} PdlArrowTable;

void pdl_arrow_table_free(PdlArrowTable* table);

/* format: 0 = Arrow IPC file, 1 = Parquet */
PdlArrowTable* pdl_arrow_read_file(const char* path, int format);

/* format: 0 = Arrow IPC file, 1 = Parquet; returns NULL on success or malloc'd error string */
char* pdl_arrow_write_file(const char* path, int format,
                           const PdlArrowColumn* cols, size_t num_cols);

#ifdef __cplusplus
}
#endif

#endif /* PDL_IO_ARROW_BRIDGE_H */
