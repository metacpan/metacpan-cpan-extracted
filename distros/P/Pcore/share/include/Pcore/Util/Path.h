# ifndef PCORE_UTIL_PATH_H
# define PCORE_UTIL_PATH_H

typedef struct {

    // is_abs
    int is_abs;

    // path
    size_t path_len;
	U8 *path;

    // volume
    size_t volume_len;
    U8 *volume;
} PcoreUtilPath;

PcoreUtilPath *normalize (U8 *buf, size_t buf_len);

# include "Pcore/Util/Path.c"

# endif
