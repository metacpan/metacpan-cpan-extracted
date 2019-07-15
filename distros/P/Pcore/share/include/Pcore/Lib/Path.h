# ifndef PCORE_LIB_PATH_H
# define PCORE_LIB_PATH_H

typedef struct {

    // is_abs
    int is_abs;

    // path
    size_t path_len;
    char *path;

    // volume
    size_t volume_len;
    char *volume;

    // dirname
    size_t dirname_len;
    char *dirname;

    // filename
    size_t filename_len;
    char *filename;

    // filename_base
    size_t filename_base_len;
    char *filename_base;

    // suffix
    size_t suffix_len;
    char *suffix;
} PcoreLibPath;

void destroyPcoreLibPath (PcoreLibPath *path);

PcoreLibPath *parse (const char *buf, size_t buf_len);

# include "Pcore/Lib/Path.c"

# endif
