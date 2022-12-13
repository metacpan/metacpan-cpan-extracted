#include "easyxs/easyxs.h"

#include <stdbool.h>
#include <stdint.h>
#include <math.h>
#include <inttypes.h>

// For some reason sys/time.h causes funky arrow-pointer errors
// in Strawberry Perl …
#ifdef _WIN32
#   include <time.h>
#else
#   include <sys/time.h>
#endif

// Windows lacks poll.h; these come from libnfs’s compat header.
#ifndef POLLIN
#   ifdef _WIN32
#       define POLLIN 0x0001
#       define POLLOUT 0x0004
#   else
#       include <poll.h>
#   endif
#endif

#include <nfsc/libnfs.h>
#include <nfsc/libnfs-raw.h>
#include <nfsc/libnfs-raw-mount.h>

#ifndef F_RDLCK
#include <fcntl.h>

// Strawberry does *not* seem to provide F_RDLCK & friends, though.
#ifndef F_RDLCK
#define F_RDLCK 0
#define F_WRLCK 1
#define F_UNLCK 2
#endif
#endif

// Taken from libnfs itself:
#define UNIX_AUTHN_MACHINE_NAME "libnfs"

#define PERL_NS "Net::LibNFS"
#define PERL_STAT_NS PERL_NS "::Stat"
#define PERL_STATVFS_NS PERL_NS "::StatVFS"
#define PERL_FH_NS PERL_NS "::Filehandle"
#define PERL_DH_NS PERL_NS "::Dirhandle"
#define PERL_DIRENT_NS PERL_NS "::DirEnt"

#define PERL_ASYNC_NS PERL_NS "::Async"
#define PERL_FH_ASYNC_NS PERL_ASYNC_NS "::Filehandle"

#define OFFSET_OF(structtype, membername) ( \
    (void*) &( ((structtype*) NULL)->membername ) - NULL \
)

#define GET_STAT64_OFFSET(membername) \
    OFFSET_OF(struct nfs_stat_64, membername)

#define _FORBID_VOID_CONTEXT \
    if (GIMME_V == G_VOID) croak("Void context is forbidden!")

unsigned char STAT64_OFFSET[] = {
    GET_STAT64_OFFSET(nfs_dev),
    GET_STAT64_OFFSET(nfs_ino),
    GET_STAT64_OFFSET(nfs_mode),
    GET_STAT64_OFFSET(nfs_nlink),
    GET_STAT64_OFFSET(nfs_uid),
    GET_STAT64_OFFSET(nfs_gid),
    GET_STAT64_OFFSET(nfs_rdev),
    GET_STAT64_OFFSET(nfs_size),
    GET_STAT64_OFFSET(nfs_blksize),
    GET_STAT64_OFFSET(nfs_blocks),
    GET_STAT64_OFFSET(nfs_atime),
    GET_STAT64_OFFSET(nfs_mtime),
    GET_STAT64_OFFSET(nfs_ctime),
    GET_STAT64_OFFSET(nfs_atime_nsec),
    GET_STAT64_OFFSET(nfs_mtime_nsec),
    GET_STAT64_OFFSET(nfs_ctime_nsec),
    GET_STAT64_OFFSET(nfs_used),
};

#define GET_DIRENT_OFFSET(membername) \
    OFFSET_OF(struct nfsdirent, membername)

unsigned char DIRENT_OFFSET[] = {
    GET_DIRENT_OFFSET(next),
    GET_DIRENT_OFFSET(name),
    GET_DIRENT_OFFSET(inode),
    GET_DIRENT_OFFSET(type),
    GET_DIRENT_OFFSET(mode),
    GET_DIRENT_OFFSET(size),
    GET_DIRENT_OFFSET(atime),
    GET_DIRENT_OFFSET(mtime),
    GET_DIRENT_OFFSET(ctime),
    GET_DIRENT_OFFSET(uid),
    GET_DIRENT_OFFSET(gid),
    GET_DIRENT_OFFSET(nlink),
    GET_DIRENT_OFFSET(dev),
    GET_DIRENT_OFFSET(rdev),
    GET_DIRENT_OFFSET(blksize),
    GET_DIRENT_OFFSET(blocks),
    GET_DIRENT_OFFSET(used),
    GET_DIRENT_OFFSET(atime_nsec),
    GET_DIRENT_OFFSET(mtime_nsec),
    GET_DIRENT_OFFSET(ctime_nsec),
};

#define GET_STATVFS64_OFFSET(membername) \
    OFFSET_OF(struct nfs_statvfs_64, membername)

unsigned char STATVFS64_OFFSET[] = {
    GET_STATVFS64_OFFSET(f_bsize),
    GET_STATVFS64_OFFSET(f_frsize),
    GET_STATVFS64_OFFSET(f_blocks),
    GET_STATVFS64_OFFSET(f_bfree),
    GET_STATVFS64_OFFSET(f_bavail),
    GET_STATVFS64_OFFSET(f_files),
    GET_STATVFS64_OFFSET(f_ffree),
    GET_STATVFS64_OFFSET(f_favail),
    GET_STATVFS64_OFFSET(f_fsid),
    GET_STATVFS64_OFFSET(f_flag),
    GET_STATVFS64_OFFSET(f_namemax),
};

typedef struct {
    struct nfs_context *nfs;
    pid_t pid;
} nlnfs_s;

typedef struct {
    struct rpc_context *rpc;
    pid_t pid;
} nlnfs_rpc_s;

typedef struct {
    struct nfsfh *nfsfh;
    SV* perl_nfs;
    pid_t pid;
} nlnfs_fh_s;

typedef struct {
    struct nfsdir *nfsdh;    // not a pointer
    SV* perl_nfs;
    pid_t pid;
    bool closed;
} nlnfs_dh_s;

typedef SV* (*_cb_parser) (pTHX_ void*, const char*, int, void *, SV**, void*);

typedef struct {
#ifdef MULTIPLICITY
    tTHX aTHX;
#endif
    SV* cb;
    void* arg;
    const char* funcname;
    _cb_parser parser;
} perl_cb_s;

static SV* _ptr_to_perl_stat_obj (pTHX_ void *data) {
    SV* retval = exs_new_structref( struct nfs_stat_64, PERL_STAT_NS );
    StructCopy(data, exs_structref_ptr(retval), struct nfs_stat_64);

    return retval;
}

static SV* _ptr_to_perl_statvfs_obj (pTHX_ void *data) {
    SV* retval = exs_new_structref( struct nfs_statvfs_64, PERL_STATVFS_NS );
    StructCopy(data, exs_structref_ptr(retval), struct nfs_statvfs_64);

    return retval;
}

SV* _ptr_to_perl_dirent_obj(pTHX_ struct nfsdirent* dent) {
    SV* retval = exs_new_structref( struct nfsdirent, PERL_DIRENT_NS );
    StructCopy(dent, exs_structref_ptr(retval), struct nfsdirent);

    return retval;
}

static void __do_perl_callback_internal(
    void* nfs_or_rpc,
    int err,
    void *data,
    void *private_data
) {
    perl_cb_s* cb_sp = (perl_cb_s*) private_data;

#ifdef MULTIPLICITY
    tTHX aTHX = cb_sp->aTHX;
#endif

    SV* err_sv = NULL;

    SV* result = cb_sp->parser(aTHX_ nfs_or_rpc, cb_sp->funcname, err, data, &err_sv, cb_sp->arg);

    SV* args[] = {
        result,
        err_sv, // If NULL then this is identical to omitting
        NULL,
    };

    SV* error = NULL;

    exs_call_sv_void_trapped(cb_sp->cb, args, &error);

    SvREFCNT_dec(cb_sp->cb);

    Safefree(cb_sp);

    if (error) warn_sv(error);
}

static void _do_perl_rpc_callback (
    struct rpc_context* rpc,
    int status,
    void* data,
    void* private_data
) {

    return __do_perl_callback_internal(rpc, status, data, private_data);
}

static void _do_perl_callback (
    int err,
    struct nfs_context *nfs,
    void *data,
    void *private_data
) {
    return __do_perl_callback_internal(nfs, err, data, private_data);
}

// snagged from Net::Libwebsockets:
static SV* _create_err_obj (pTHX_ const char* type, unsigned argscount, ...) {

    // If argscount == 1:
    //  create_args[0] is the type
    //  create_args[1] is the arg
    //  create_args[2] is NULL

    SV* create_args[argscount+2];
    create_args[0] = newSVpv(type, 0);
    create_args[argscount+1] = NULL;

    va_list args;
    va_start(args, argscount);

    for (unsigned a=0; a<argscount; a++) {
        create_args[a+1] = va_arg(args, SV*);
    }

    va_end(args);

    SV* x_class_sv = newSVpvs(PERL_NS "::X");

    load_module(PERL_LOADMOD_NOIMPORT, newSVsv(x_class_sv), NULL);

    return exs_call_method_scalar(
        sv_2mortal(x_class_sv),
        "create",
        create_args
    );
}

static SV* _create_nfs_errno (pTHX_ struct nfs_context* nfs, const char* funcname, int error, const char* errstr) {

    const char* errstr2 = errstr ? errstr : nfs_get_error(nfs);

    return _create_err_obj(aTHX_ "NFSError", 3,
        newSVpv(funcname, 0),
        newSViv(-error),
        newSVpv(errstr2, 0)
    );
}

static SV* _create_rpc_errno (pTHX_ struct rpc_context* rpc, const char* funcname, int error, const char* errstr) {

    const char* errstr2 = errstr ? errstr : rpc_get_error(rpc);

    return _create_nfs_errno(aTHX_ NULL, funcname, error, errstr2);
}

static void _croak_nfs_errno (pTHX_ struct nfs_context* nfs, const char* funcname, int error, const char* errstr) {

    const char* str = errstr ? errstr : nfs_get_error(nfs);

    croak_sv( _create_nfs_errno(aTHX_ nfs, funcname, error, str) );
}

unsigned _count_exports( struct exportnode* node ) {
    unsigned h=0;

    while (node) {
        h++;
        node = node->ex_next;
    }

    return h;
}

void _parse_exports_to_hrs( pTHX_ struct exportnode* nodes, SV** export_hrs ) {
    unsigned h=0;

    struct exportnode* node = nodes;
    while (node) {
        SV* path = newSVpv(node->ex_dir, 0);

        AV* groups_av = newAV();

        groupnode* curgroup = node->ex_groups;
        while (curgroup) {
            SV* name = newSVpv(curgroup->gr_name, 0);
            av_push(groups_av, name);

            curgroup = curgroup->gr_next;
        }

        HV* export_hv = newHV();
        hv_stores(export_hv, "dir", path);
        hv_stores(export_hv, "groups", newRV_noinc((SV*) groups_av));

        export_hrs[h] = newRV_noinc((SV*) export_hv);

        node = node->ex_next;
    }
}

// ----------------------------------------------------------------------

static struct timeval _parse_time_sv (pTHX_ SV* time_sv) {
    time_t secs;
    useconds_t microsecs;

    if (SvROK(time_sv)) {
        bool ok = false;

        SV* referent = SvRV(time_sv);

        if (SvTYPE(referent) == SVt_PVAV) {
            AV* times_arr = (AV*) referent;

            if (av_tindex(times_arr) == 1) {
                secs = exs_SvUV( *(av_fetch(times_arr, 0, 0)) );
                microsecs = exs_SvUV( *(av_fetch(times_arr, 1, 0)) );
                ok = true;
            }
        }

        if (!ok) {
            croak("%" SVf " must be either a nonnegative number or an arrayref of 2 nonnegative integers", time_sv);
        }
    }
    else if (SvIOK(time_sv)) {
        IV floatval = SvIV(time_sv);

        if (floatval < 0) croak("Time (%" IVdf " must be positive!", floatval);

        secs = floatval;
        microsecs = 0;
    }
    else {
        NV floatval = SvNV(time_sv);

        if (floatval < 0) croak("Time (%" NVff " must be positive!", floatval);

        secs = floor(floatval);
        microsecs = floatval * 1000000;
    }

    return (struct timeval) {
        .tv_sec = secs,
        .tv_usec = microsecs,
    };
}

// ----------------------------------------------------------------------

union fcntl_arg {
    struct nfs4_flock flock;
};

static inline void _set_fcntl_arg (pTHX_ enum nfs4_fcntl_op cmd, union fcntl_arg* arg, SV** args, unsigned argslen) {

    *arg = (union fcntl_arg) {
        .flock = { 0 },
    };

    unsigned argsmin;
    unsigned argsmax;

    switch (cmd) {
        case NFS4_F_SETLK:
        case NFS4_F_SETLKW:
            argsmin = 2;
            argsmax = 4;

            arg->flock.l_type = SvIV(args[0]);    // TODO: strict
            arg->flock.l_whence = SvIV(args[1]);

            if (argslen > 2) {

                /* It’s unclear why l_start is uint64_t rather than int64_t
                   since fcntl(2) defines it as off_t (i.e., signed).
                */
                arg->flock.l_start = exs_SvUV(args[2]);

                if (argslen > 3) {
                    arg->flock.l_len = exs_SvUV(args[3]);
                }
            }

        default:
            croak("%s: Unknown op: %u", __func__, cmd);
            assert(0);
    }

    // We assume an extra arg for the command (e.g., NFS4_F_SETLK).

    if (argsmin > argslen) {
        croak("Need at least %u args; got %d", 1 + argsmin, 1 + argslen);
    }
    else if (argsmax < argslen) {
        croak("Need at most %u args; got %d", 1 + argsmax, 1 + argslen);
    }
}

// ----------------------------------------------------------------------

static SV* _create_perl_fh(pTHX_ SV* self_sv, struct nfsfh* nfsfh) {
    SV* retval = exs_new_structref(nlnfs_fh_s, PERL_FH_NS);
    nlnfs_fh_s* perl_nfs_fh = exs_structref_ptr(retval);

    *perl_nfs_fh = (nlnfs_fh_s) {
        .nfsfh = nfsfh,
        .perl_nfs = SvREFCNT_inc(self_sv),
        .pid = getpid(),
    };

    return retval;
}

static SV* _create_perl_dh(pTHX_ SV* self_sv, struct nfsdir *nfsdh) {
    SV* retval = exs_new_structref(nlnfs_dh_s, PERL_DH_NS);
    nlnfs_dh_s* perl_nfs_dh = exs_structref_ptr(retval);

    *perl_nfs_dh = (nlnfs_dh_s) {
        .nfsdh = nfsdh,
        .perl_nfs = SvREFCNT_inc(self_sv),
        .pid = getpid(),
    };

    return retval;
}

// ----------------------------------------------------------------------

static SV* _parse_mount_getexports (pTHX_ void* rpc, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    PERL_UNUSED_ARG(arg);

    SV* retval;

    if (err) {
        *err_sv = _create_rpc_errno(aTHX_ rpc, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        struct exportnode* node0 = *(exports *)data;
        unsigned count = _count_exports(node0);

        SV* export_hrs[count];

        _parse_exports_to_hrs(aTHX_ node0, export_hrs);

        AV* ret_av = newAV();
        av_extend(ret_av, count-1);

        for (unsigned c=0; c<count; c++) {
            av_store(ret_av, c, export_hrs[c]);
        }

        retval = newRV_noinc( (SV*) ret_av );
    }

    return retval;
}

static SV* _parse_readlink_async (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    PERL_UNUSED_ARG(arg);

    SV* retval;

    if (err) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        retval = newSVpv(data, 0);
    }

    return retval;
}

static SV* _parse_fallible_empty_return (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    PERL_UNUSED_ARG(arg);

    if (err) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
    }

    return &PL_sv_undef;
}

static SV* _parse_stat64_async (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    PERL_UNUSED_ARG(arg);

    SV* retval;

    if (err) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        assert(data);
        retval = _ptr_to_perl_stat_obj(aTHX_ data);
    }

    return retval;
}

static SV* _parse_statvfs64_async (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    PERL_UNUSED_ARG(arg);

    SV* retval;

    if (err) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        assert(data);
        retval = _ptr_to_perl_statvfs_obj(aTHX_ data);
    }

    return retval;
}

static SV* _parse_open_async (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    SV* perl_nfs_sv = arg;

    SV* retval;

    if (err) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        assert(data);
        retval = _create_perl_fh(aTHX_ perl_nfs_sv, data);
    }

    SvREFCNT_dec(perl_nfs_sv);

    return retval;
}

static SV* _parse_opendir_async (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    SV* perl_nfs_sv = arg;

    SV* retval;

    if (err) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        assert(data);
        retval = _create_perl_dh(aTHX_ perl_nfs_sv, data);
    }

    SvREFCNT_dec(perl_nfs_sv);

    return retval;
}

static SV* _parse_read_async (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    PERL_UNUSED_ARG(arg);

    SV* retval;

    if (err < 0) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        assert(data);

        retval = newSVpvn(data, err);
    }

    return retval;
}

static SV* _parse_write_async (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    SV* retval;

    if (err < 0) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        retval = newSViv(err);
    }

    return retval;
}

static SV* _parse_lseek_async (pTHX_ void* nfs, const char* funcname, int err, void *data, SV** err_sv, void* arg) {
    SV* retval;

    if (err < 0) {
        *err_sv = _create_nfs_errno(aTHX_ nfs, funcname, err, data);
        retval = &PL_sv_undef;
    }
    else {
        uint64_t *pos_p = data;
        retval = newSVuv(*pos_p);
    }

    return retval;
}

// ----------------------------------------------------------------------

typedef void (*_lnfs_string_setter) (struct nfs_context*, const char*);

typedef struct {
    const char* name;
    _lnfs_string_setter func;
} _string_setting_s;

static const _string_setting_s STRING_SETTINGS[] = {
#ifdef HAVE_SO_BINDTODEVICE
    { .name = "interface", .func = nfs_set_interface },
#endif
    { .name = "client_name", .func = nfs4_set_client_name },
    { .name = "verifier", .func = nfs4_set_verifier },
};

static const unsigned STRING_SETTINGS_COUNT = sizeof(STRING_SETTINGS) / sizeof(_string_setting_s);

// ----------------------------------------------------------------------

typedef void (*_lnfs_int_setter) (struct nfs_context*, int);

typedef struct {
    const char* name;
    _lnfs_int_setter func;
} _int_setting_s;

static const _int_setting_s INT_SETTINGS[] = {
    { .name = "tcp_syncnt", .func = nfs_set_tcp_syncnt },
    { .name = "debug", .func = nfs_set_debug },
#ifdef NLNFS_NFS_SET_AUTO_TRAVERSE_MOUNTS
    { .name = "auto_traverse_mounts", .func = nfs_set_auto_traverse_mounts },
#endif
    { .name = "dircache", .func = nfs_set_dircache },
    { .name = "autoreconnect", .func = nfs_set_autoreconnect },
    { .name = "timeout", .func = nfs_set_timeout },
#ifdef NLNFS_NFS_SET_NFSPORT
    { .name = "nfsport", .func = nfs_set_nfsport },
#endif
#ifdef NLNFS_NFS_SET_MOUNTPORT
    { .name = "mountport", .func = nfs_set_mountport },
#endif
};

static const unsigned INT_SETTINGS_COUNT = sizeof(INT_SETTINGS) / sizeof(_int_setting_s);

// ----------------------------------------------------------------------

typedef void (*_lnfs_u32_setter) (struct nfs_context*, uint32_t);

typedef struct {
    const char* name;
    _lnfs_u32_setter func;
} _u32_setting_s;

static const _u32_setting_s U32_SETTINGS[] = {
    { .name = "uid", .func = (_lnfs_u32_setter) nfs_set_uid },
    { .name = "gid", .func = (_lnfs_u32_setter) nfs_set_gid },
    { .name = "pagecache", .func = nfs_set_pagecache },
    { .name = "pagecache_ttl", .func = nfs_set_pagecache_ttl },
    { .name = "readahead", .func = nfs_set_readahead },
};

static const unsigned U32_SETTINGS_COUNT = sizeof(U32_SETTINGS) / sizeof(_u32_setting_s);

// ----------------------------------------------------------------------

typedef void (*_lnfs_u64_setter) (struct nfs_context*, uint64_t);

typedef struct {
    const char* name;
    _lnfs_u64_setter func;
} _u64_setting_s;

static const _u64_setting_s U64_SETTINGS[] = {
    { .name = "readmax", .func = nfs_set_readmax },
    { .name = "writemax", .func = nfs_set_writemax },
};

static const unsigned U64_SETTINGS_COUNT = sizeof(U64_SETTINGS) / sizeof(_u64_setting_s);

// ----------------------------------------------------------------------

perl_cb_s* _create_callback_struct (pTHX_ const char* funcname, SV* cb, _cb_parser parser, void* arg) {
    perl_cb_s* cb_sp;
    Newx(cb_sp, 1, perl_cb_s);

    *cb_sp = (perl_cb_s) {
#ifdef MULTIPLICITY
        .aTHX = aTHX,
#endif
        .cb = SvREFCNT_inc(cb),
        .funcname = funcname,
        .parser = parser,
        .arg = arg,
    };

    return cb_sp;
}

// ----------------------------------------------------------------------

typedef int (*_nfs_statfunc) (struct nfs_context*, const char*, struct nfs_stat_64*);

SV* _stat_path_xsub (pTHX_ SV* self_sv, SV* path_sv, _nfs_statfunc func, const char* funcname) {
    nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);
    struct nfs_stat_64 st;

    const char* path = exs_SvPVbyte_nolen(path_sv);

    int err = func( perl_nfs->nfs, path, &st );

    if (err) {
        _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
    }

    return _ptr_to_perl_stat_obj(aTHX_ &st);
}

// ----------------------------------------------------------------------

typedef int (*_nfs_void_pathfunc) (struct nfs_context*, const char*);
typedef int (*_nfs_async_void_pathfunc) (struct nfs_context*, const char*, nfs_cb, void*);

static _nfs_void_pathfunc VOID_PATHFUNC_BY_IX[] = {
    nfs_rmdir,
    nfs_chdir,
    nfs_unlink,
};

static _nfs_async_void_pathfunc ASYNC_VOID_PATHFUNC_BY_IX[] = {
    nfs_rmdir_async,
    nfs_chdir_async,
    nfs_unlink_async,
};

const char* VOID_PATHFUNC_NAME_BY_IX[] = {
    "rmdir",
    "chdir",
    "unlink",
};

typedef int (*_nfs_void_2pathfunc) (struct nfs_context*, const char*, const char*);
typedef int (*_nfs_async_void_2pathfunc) (struct nfs_context*, const char*, const char*, nfs_cb, void*);

static _nfs_void_2pathfunc VOID_2PATHFUNC_BY_IX[] = {
    nfs_symlink,
    nfs_rename,
    nfs_link,
};

static _nfs_async_void_2pathfunc ASYNC_VOID_2PATHFUNC_BY_IX[] = {
    nfs_symlink_async,
    nfs_rename_async,
    nfs_link_async,
};

const char* VOID_2PATHFUNC_NAME_BY_IX[] = {
    "symlink",
    "rename",
    "link",
};

// ----------------------------------------------------------------------

static inline void _croak_if_buffer_is_reference( pTHX_ SV* buf_sv ) {
    if (SvROK(buf_sv)) {
        croak("Given buffer must be a plain scalar, not %" SVf, buf_sv);
    }
}

#define _croak_if_uv_exceeds_u32(name, value) \
    if (value > UINT32_MAX) croak("%s: value (%" UVuf ") exceeds maximum (%" PRIu32 ")", name, value, UINT32_MAX);

// ----------------------------------------------------------------------

static void _utime_ish (pTHX_ int ix, SV* self_sv, SV* path_sv, SV* atime_sv, SV* mtime_sv, SV* cb) {
    nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

    const char* path = exs_SvPVbyte_nolen(path_sv);
    struct timeval times_arr[] = {
        _parse_time_sv(aTHX_ atime_sv),
        _parse_time_sv(aTHX_ mtime_sv),
    };

    int err;

    const char* funcname = ix ? "lutimes" : "utimes";

    if (cb) {
        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_fallible_empty_return, NULL);

        if (ix) {
            err = nfs_lutimes_async(perl_nfs->nfs, path, times_arr, _do_perl_callback, cb_sp);
        }
        else {
            err = nfs_utimes_async(perl_nfs->nfs, path, times_arr, _do_perl_callback, cb_sp);
        }
    }
    else if (ix) {
        err = nfs_lutimes(perl_nfs->nfs, path, times_arr);
    }
    else {
        err = nfs_utimes(perl_nfs->nfs, path, times_arr);
    }

    if (err) {
        _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
    }

    return;
}

static SV* _read_or_pread (pTHX_ SV* self_sv, SV* offset_sv, SV* count_sv, SV* cb) {

    uint64_t count = exs_SvUV(count_sv);
    if (count < 1) croak("Count (%" SVf ") must be positive!", count_sv);

    uint64_t offset;
    if (offset_sv) offset = exs_SvUV(offset_sv);

    nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

    SV* nfs_sv = nfs_fh->perl_nfs;

    nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

    const char* funcname = offset_sv ? "pread" : "read";

    SV* RETVAL;
    int status;

    if (cb) {
        RETVAL = NULL;

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_read_async, NULL);

        if (offset_sv) {
            status = nfs_pread_async(perl_nfs->nfs, nfs_fh->nfsfh, offset, count, _do_perl_callback, cb_sp);
        }
        else {
            status = nfs_read_async(perl_nfs->nfs, nfs_fh->nfsfh, count, _do_perl_callback, cb_sp);
        }
    }
    else {
        RETVAL = newSV(count);
        SvPOK_on(RETVAL);

        void *buf = SvPVX(RETVAL);

        if (offset_sv) {
            status = nfs_pread(perl_nfs->nfs, nfs_fh->nfsfh, offset, count, buf);
        }
        else {
            status = nfs_read(perl_nfs->nfs, nfs_fh->nfsfh, count, buf);
        }
    }

    if (status < 0) {
        if (RETVAL) sv_2mortal(RETVAL);
        _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, status, NULL);
    }

    if (!cb) {
        assert(status <= count);

        if (status != count) {
            char* p = SvPVX(RETVAL);
            p[status] = '\0';
        }

        SvCUR_set(RETVAL, status);
    }

    return RETVAL;
}

// offset_sv == NULL iff write
// cb == NULL iff sync
//
static int _write_or_pwrite (pTHX_ SV* self_sv, SV* offset_sv, SV* buf_sv, SV* cb) {
    _croak_if_buffer_is_reference(aTHX_ buf_sv);

    uint64_t offset;
    if (offset_sv) offset = exs_SvUV(offset_sv);

    nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

    SV* nfs_sv = nfs_fh->perl_nfs;

    nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

    STRLEN buflen;
    const char* buf = SvPVbyte(buf_sv, buflen);

    if (buflen == 0) croak("Given buffer must be nonempty");

    int RETVAL;

    const char *funcname = offset_sv ? "pwrite" : "write";

    if (cb) {
        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_write_async, NULL);

        if (offset_sv) {
            RETVAL = nfs_pwrite_async(perl_nfs->nfs, nfs_fh->nfsfh, offset, buflen, buf, _do_perl_callback, cb_sp);
        }
        else {
            RETVAL = nfs_write_async(perl_nfs->nfs, nfs_fh->nfsfh, buflen, buf, _do_perl_callback, cb_sp);
        }
    }
    else if (offset_sv) {
        RETVAL = nfs_pwrite(perl_nfs->nfs, nfs_fh->nfsfh, offset, buflen, buf);
    }
    else {
        RETVAL = nfs_write(perl_nfs->nfs, nfs_fh->nfsfh, buflen, buf);
    }

    if (RETVAL < 0) {
        _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, RETVAL, NULL);
    }

    return RETVAL;
}

// NB: libnfs 5.0.2 added the ability to set auxiliary GIDs, which would
// obviate this functionality; however, by retaining it we allow pre-5.0.2
// libnfs releases to set aux GIDs. So there’s little incentive to adopt
// libnfs’s new hotness.
//
static void _set_unix_authn(pTHX_ struct nfs_context* nfs, SV* value_sv) {

    if (!SvROK(value_sv) || (SvTYPE(SvRV(value_sv)) != SVt_PVAV)) {
        croak("“%s” must be an array reference, not %" SVf, "unix_authn", value_sv);
    }

    AV* authn_av = (AV*) SvRV(value_sv);
    uint32_t nums_count = 1 + av_len(authn_av);
    if (nums_count < 2) croak("“%s” must contain at least 2 numbers", "unix_authn");

    uint32_t nums[nums_count];

    for (unsigned n=0; n<nums_count; n++) {
        SV** svp = av_fetch(authn_av, n, 0);
        assert(svp);

        UV value = exs_SvUV(*svp);

        // The RPC protocol transmits these values using 4 bytes.
        // Thus, u32 is the maximum, despite libnfs’s use of plain int
        // for these values.
        //
        _croak_if_uv_exceeds_u32("unix_authn", value);

        nums[n] = value;
    }

    struct AUTH* auth = libnfs_authunix_create(UNIX_AUTHN_MACHINE_NAME, nums[0], nums[1], nums_count - 2, 2 + nums);
    assert(auth);

    nfs_set_auth(nfs, auth);
}

#ifdef NLNFS_NFS_SET_READDIR_MAX_BUFFER_SIZE

#define MAX_BUFFER_SIZE_ARRAY_SIZE 2
#define READDIR_BUFFER_SETTING "readdir_buffer"

static void _set_readdir_max_buffer_size(pTHX_ struct nfs_context* nfs, SV* value_sv) {

    uint32_t dircount, maxcount;

    if (SvROK(value_sv) && (SvTYPE(SvRV(value_sv)) == SVt_PVAV)) {
        AV* av = (AV*) SvRV(value_sv);
        uint32_t nums_count = 1 + av_len(av);
        if (nums_count != MAX_BUFFER_SIZE_ARRAY_SIZE) croak("“%s” must contain exactly %d numbers", READDIR_BUFFER_SETTING, MAX_BUFFER_SIZE_ARRAY_SIZE);

        uint32_t nums[MAX_BUFFER_SIZE_ARRAY_SIZE];

        for (unsigned n=0; n<nums_count; n++) {
            SV** svp = av_fetch(av, n, 0);
            assert(svp);

            UV value = exs_SvUV(*svp);
            _croak_if_uv_exceeds_u32(READDIR_BUFFER_SETTING, value);

            nums[n] = value;
        }

        dircount = nums[0];
        maxcount = nums[1];
    } else if (SvROK(value_sv)) {
        croak("“%s” must be an array reference or scalar, not %" SVf, READDIR_BUFFER_SETTING, value_sv);
    } else {
        UV value = exs_SvUV(value_sv);
        _croak_if_uv_exceeds_u32(READDIR_BUFFER_SETTING, value);

        dircount = value;
        maxcount = value;
    }

    nfs_set_readdir_max_buffer_size(nfs, dircount, maxcount);
}
#endif

// ----------------------------------------------------------------------

MODULE = Net::LibNFS        PACKAGE = Net::LibNFS

PROTOTYPES: DISABLE

BOOT:
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "_POLLIN", newSVuv(POLLIN));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "_POLLOUT", newSVuv(POLLOUT));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "NFS4_F_SETLK", newSVuv(NFS4_F_SETLK));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "NFS4_F_SETLKW", newSVuv(NFS4_F_SETLKW));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "F_RDLCK", newSVuv(F_RDLCK));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "F_WRLCK", newSVuv(F_WRLCK));
    newCONSTSUB(gv_stashpv(PERL_NS, 0), "F_UNLCK", newSVuv(F_UNLCK));

# ----------------------------------------------------------------------
# Static functions

void
find_local_servers ()
    PPCODE:
        struct nfs_server_list *servers = nfs_find_local_servers();

        if (!servers) {
            XSRETURN_EMPTY;
        }

        struct nfs_server_list *srvlist = servers;
        struct nfs_server_list *cur_srv = srvlist;

        unsigned srvcount = 0;

        while (cur_srv) {
            srvcount++;
            cur_srv = cur_srv->next;
        }

        cur_srv = srvlist;

        if (srvcount) {
            EXTEND(SP, srvcount);

            while (cur_srv) {
                mPUSHs( newSVpv(cur_srv->addr, 0) );
                cur_srv = cur_srv->next;
            }
        }

        free_nfs_srvr_list(srvlist);

void
mount_getexports (SV* server_sv, SV* timeout_sv=&PL_sv_undef)
    PPCODE:
        const char* server = exs_SvPVbyte_nolen(server_sv);

        struct exportnode* nodes;

        if (SvOK(timeout_sv)) {
            int timeout = SvIV(timeout_sv); // TODO
            nodes = mount_getexports_timeout(server, timeout);
        }
        else {
            nodes = mount_getexports(server);
        }

        if (!nodes) {
            XSRETURN_EMPTY;
        }

        unsigned exports_count = _count_exports(nodes);
        SV* export_hrs[exports_count];

        _parse_exports_to_hrs( aTHX_ nodes, export_hrs );

        mount_free_export_list(nodes);

# ----------------------------------------------------------------------

SV*
new (const char* classname)
    CODE:
        struct nfs_context *nfs = nfs_init_context();
        if (NULL == nfs) {
            croak("Failed to init libnfs context");
        }

        RETVAL = exs_new_structref(nlnfs_s, classname);
        nlnfs_s* perl_nfs = exs_structref_ptr(RETVAL);

        *perl_nfs = (nlnfs_s) {
            .nfs = nfs,
            .pid = getpid(),
        };

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        if (perl_nfs->pid == getpid() && PL_dirty) {
            warn("%" SVf ": DESTROY at global destruction; memory leak likely!\n", self_sv);
        }

        assert(perl_nfs);
        assert(perl_nfs->nfs);

        nfs_destroy_context(perl_nfs->nfs);

SV*
set (SV* self_sv, ...)
    CODE:
        if (!(items % 2)) {
            IV items_iv = items;
            croak("Uneven args list (%" IVdf " args) given!", items_iv-1);
        }

        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        unsigned a=1;
        for (; a<items; a++) {
            const char* param = exs_SvPVbyte_nolen(ST(a));

            SV* value_sv = ST(++a);

            // int --------------------------------------------------

            unsigned ss;

            for (ss=0; ss<INT_SETTINGS_COUNT; ss++) {
                if (strcmp(param, INT_SETTINGS[ss].name)) continue;

                int value = SvIV(value_sv);

                INT_SETTINGS[ss].func(perl_nfs->nfs, value);

                break;
            }

            if (ss != INT_SETTINGS_COUNT) continue;

            // uint32_t --------------------------------------------------

            for (ss=0; ss<U32_SETTINGS_COUNT; ss++) {
                if (strcmp(param, U32_SETTINGS[ss].name)) continue;

                UV value = exs_SvUV(value_sv);

                _croak_if_uv_exceeds_u32(param, value);

                U32_SETTINGS[ss].func(perl_nfs->nfs, value);

                break;
            }

            if (ss != U32_SETTINGS_COUNT) continue;

            // uint64_t --------------------------------------------------

            for (ss=0; ss<U64_SETTINGS_COUNT; ss++) {
                if (strcmp(param, U64_SETTINGS[ss].name)) continue;

                UV value = exs_SvUV(value_sv);

                U64_SETTINGS[ss].func(perl_nfs->nfs, value);

                break;
            }

            if (ss != U64_SETTINGS_COUNT) continue;

            // special --------------------------------------------------

            if (!strcmp(param, "version")) {
                int value = SvIV(value_sv);
                int err = nfs_set_version(perl_nfs->nfs, value);

                if (err) {
                    croak_sv( _create_err_obj(aTHX_ "Generic", 1,
                        newSVpv(nfs_get_error(perl_nfs->nfs), 0) )
                    );
                }

                continue;
            }

            if (!strcmp(param, "unix_authn")) {
                _set_unix_authn(aTHX_ perl_nfs->nfs, value_sv);

                continue;
            }
#ifdef NLNFS_NFS_SET_READDIR_MAX_BUFFER_SIZE

            if (!strcmp(param, READDIR_BUFFER_SETTING)) {
                _set_readdir_max_buffer_size(aTHX_ perl_nfs->nfs, value_sv);

                continue;
            }
#endif

            // string --------------------------------------------------

            for (ss=0; ss<STRING_SETTINGS_COUNT; ss++) {
                if (strcmp(param, STRING_SETTINGS[ss].name)) continue;

                const char* value = exs_SvPVbyte_nolen(value_sv);

                STRING_SETTINGS[ss].func(perl_nfs->nfs, value);

                break;
            }

            if (ss == STRING_SETTINGS_COUNT) {
                croak("Unknown setting: %s", param);
            }
        }

        RETVAL = SvREFCNT_inc(self_sv);

    OUTPUT:
        RETVAL

int
queue_length (SV* self_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);
        RETVAL = nfs_queue_length( perl_nfs->nfs );
    OUTPUT:
        RETVAL

uint64_t
get_readmax (SV* self_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);
        RETVAL = nfs_get_readmax( perl_nfs->nfs );
    OUTPUT:
        RETVAL

uint64_t
get_writemax (SV* self_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);
        RETVAL = nfs_get_writemax( perl_nfs->nfs );
    OUTPUT:
        RETVAL

int
get_version (SV* self_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);
        RETVAL = nfs_get_version( perl_nfs->nfs );
    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

UV
umask (SV* self_sv, SV* new)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);
        UV new_uv = exs_SvUV(new);
        if (new_uv > UINT16_MAX) {
            croak("Invalid umask (%" UVuf ") given", new_uv);
        }

        RETVAL = nfs_umask(perl_nfs->nfs, new_uv);
    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

SV*
mount (SV* self_sv, SV* server_sv, SV* exportname_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* server = exs_SvPVbyte_nolen(server_sv);
        const char* exportname = exs_SvPVbyte_nolen(exportname_sv);

        int error = nfs_mount(perl_nfs->nfs, server, exportname);

        if (error) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "mount", error, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_mount (SV* self_sv, SV* server_sv, SV* exportname_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* server = exs_SvPVbyte_nolen(server_sv);
        const char* exportname = exs_SvPVbyte_nolen(exportname_sv);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "mount", cb, _parse_fallible_empty_return, NULL);

        int err = nfs_mount_async(perl_nfs->nfs, server, exportname, _do_perl_callback, cb_sp);
        if (err) croak("%s failed!", "nfs_mount_async");

SV*
umount (SV* self_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        int error = nfs_umount(perl_nfs->nfs);

        if (error) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "umount", error, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_umount (SV* self_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "umount", cb, _parse_fallible_empty_return, NULL);

        int err = nfs_umount_async(perl_nfs->nfs, _do_perl_callback, cb_sp);
        if (err) croak("%s failed!", "nfs_umount_async");

SV*
stat (SV* self_sv, SV* path_sv)
    ALIAS:
        lstat = 1
    CODE:
        RETVAL = _stat_path_xsub(aTHX_
            self_sv, path_sv,
            ix ? nfs_lstat64 : nfs_stat64,
            ix ? "lstat" : "stat"
        );

    OUTPUT:
        RETVAL

void
_async_stat (SV* self_sv, SV* path_sv, SV* cb)
    ALIAS:
        _async_lstat = 1
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ ix ? "lstat" : "stat", cb, _parse_stat64_async, NULL);

        int err;
        if (ix) {
            err = nfs_lstat64_async(perl_nfs->nfs, path, _do_perl_callback, cb_sp);
        }
        else {
            err = nfs_stat64_async(perl_nfs->nfs, path, _do_perl_callback, cb_sp);
        }

        if (err) croak("%s failed!", ix ? "nfs_lstat64_async" : "nfs_stat64_async");

# TODO: fstat

SV*
open (SV* self_sv, SV* path_sv, SV* flags_sv, SV* mode_sv=&PL_sv_undef)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);
        int flags = SvIV(flags_sv); // TODO: stricter

        struct nfsfh* nfsfh;

        int err;

        if (SvOK(mode_sv)) {
            int mode = SvIV(mode_sv);   // TODO: stricter
            err = nfs_open2(perl_nfs->nfs, path, flags, mode, &nfsfh);
        }
        else {
            err = nfs_open(perl_nfs->nfs, path, flags, &nfsfh);
        }

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "open", err, NULL);
        }

        RETVAL = _create_perl_fh(aTHX_ self_sv, nfsfh);

    OUTPUT:
        RETVAL

void
_async_open (SV* self_sv, SV* path_sv, SV* flags_sv, SV* mode_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);
        int flags = SvIV(flags_sv); // TODO: stricter

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "open", cb, _parse_open_async, self_sv);

        int err;

        if (SvOK(mode_sv)) {
            int mode = SvIV(mode_sv);   // TODO: stricter
            err = nfs_open2_async(perl_nfs->nfs, path, flags, mode, _do_perl_callback, cb_sp);
        }
        else {
            err = nfs_open_async(perl_nfs->nfs, path, flags, _do_perl_callback, cb_sp);
        }

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "open", err, NULL);
        }

        // Increment self_sv’s refcount because it’s part of
        // the callback struct. _parse_open_async() will free this up.
        SvREFCNT_inc(self_sv);

SV*
mkdir (SV* self_sv, SV* path_sv, SV* mode_sv=&PL_sv_undef)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        int err;

        if (SvOK(mode_sv)) {
            int mode = SvIV(mode_sv);   // TODO: stricter
            err = nfs_mkdir2(perl_nfs->nfs, path, mode);
        }
        else {
            err = nfs_mkdir(perl_nfs->nfs, path);
        }

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "mkdir", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);

    OUTPUT:
        RETVAL

void
_async_mkdir (SV* self_sv, SV* path_sv, SV* mode_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        int err;

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "mkdir", cb, _parse_fallible_empty_return, NULL);

        char* funcname;

        if (SvOK(mode_sv)) {
            int mode = SvIV(mode_sv);   // TODO: stricter
            err = nfs_mkdir2_async(perl_nfs->nfs, path, mode, _do_perl_callback, cb_sp);
            funcname = "nfs_mkdir2_async";
        }
        else {
            err = nfs_mkdir_async(perl_nfs->nfs, path, _do_perl_callback, cb_sp);
            funcname = "nfs_mkdir_async";
        }

        if (err) croak("%s failed!", funcname);

SV*
rmdir (SV* self_sv, SV* path_sv)
    ALIAS:
        chdir = 1
        unlink = 2
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        _nfs_void_pathfunc func = VOID_PATHFUNC_BY_IX[ix];

        int err = func( perl_nfs->nfs, path );

        if (err) {
            const char* funcname = VOID_PATHFUNC_NAME_BY_IX[ix];
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);

    OUTPUT:
        RETVAL

void
_async_rmdir (SV* self_sv, SV* path_sv, SV* cb)
    ALIAS:
        _async_chdir = 1
        _async_unlink = 2
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        const char* funcname = VOID_PATHFUNC_NAME_BY_IX[ix];

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_fallible_empty_return, NULL);

        _nfs_async_void_pathfunc func = ASYNC_VOID_PATHFUNC_BY_IX[ix];
        int err = func( perl_nfs->nfs, path, _do_perl_callback, cb_sp );

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

SV*
mknod (SV* self_sv, SV* path_sv, SV* mode_sv, SV* dev_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);
        int mode = SvIV(mode_sv);
        int dev = SvIV(dev_sv);

        int err = nfs_mknod(perl_nfs->nfs, path, mode, dev);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "mknod", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);

    OUTPUT:
        RETVAL

void
_async_mknod (SV* self_sv, SV* path_sv, SV* mode_sv, SV* dev_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);
        int mode = SvIV(mode_sv);
        int dev = SvIV(dev_sv);

        const char* funcname = "mknod";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_fallible_empty_return, NULL);

        int err = nfs_mknod_async( perl_nfs->nfs, path, mode, dev, _do_perl_callback, cb_sp );

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

SV*
opendir (SV* self_sv, SV* path_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        struct nfsdir *nfsdir = { NULL };

        int err = nfs_opendir(perl_nfs->nfs, path, &nfsdir);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "opendir", err, NULL);
        }

        RETVAL = _create_perl_dh(aTHX_ self_sv, nfsdir);
    OUTPUT:
        RETVAL

void
_async_opendir (SV* self_sv, SV* path_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        const char* funcname = "opendir";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_opendir_async, self_sv);

        int err = nfs_opendir_async(perl_nfs->nfs, path, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

        SvREFCNT_inc(self_sv);

const char*
getcwd (SV* self_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char *cwd = NULL;
        nfs_getcwd( perl_nfs->nfs, &cwd );

        RETVAL = cwd;
    OUTPUT:
        RETVAL

SV*
statvfs (SV* self_sv, SV* path_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        struct nfs_statvfs_64 svfs;

        int err = nfs_statvfs64(perl_nfs->nfs, path, &svfs);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "statvfs", err, NULL);
        }

        RETVAL = _ptr_to_perl_statvfs_obj(aTHX_ &svfs);
    OUTPUT:
        RETVAL

void
_async_statvfs (SV* self_sv, SV* path_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        const char* funcname = "statvfs";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_statvfs64_async, NULL);

        int err = nfs_statvfs64_async(perl_nfs->nfs, path, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

SV*
readlink (SV* self_sv, SV* path_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        char* dest;

        int err = nfs_readlink2(perl_nfs->nfs, path, &dest);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "readlink", err, NULL);
        }

        // We could reuse dest as RETVAL’s PV, but that gets dicey because
        // we should only do that with buffers allocated by Newx, which
        // dest isn’t. So, safety first.
        //
        int len = strlen(dest);
        RETVAL = newSVpvn(dest, len);

        free(dest);

    OUTPUT:
        RETVAL

void
_async_readlink (SV* self_sv, SV* path_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        const char* funcname = "readlink";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_readlink_async, NULL);

        int err = nfs_readlink_async(perl_nfs->nfs, path, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

SV*
chmod (SV* self_sv, SV* path_sv, SV* mode_sv)
    ALIAS:
        lchmod = 1
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);
        int mode = SvIV(mode_sv);   // TODO

        int err;

        if (ix) {
            err = nfs_lchmod(perl_nfs->nfs, path, mode);
        }
        else {
            err = nfs_chmod(perl_nfs->nfs, path, mode);
        }

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, ix ? "lchmod" : "chmod", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

SV*
utime (SV* self_sv, SV* path_sv, SV* atime_sv, SV* mtime_sv)
    ALIAS:
        lutime = 1
    CODE:
        _utime_ish(aTHX_ ix, self_sv, path_sv, atime_sv, mtime_sv, NULL);

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_utime (SV* self_sv, SV* path_sv, SV* atime_sv, SV* mtime_sv, SV* cb)
    ALIAS:
        _async_lutime = 1
    CODE:
        _utime_ish(aTHX_ ix, self_sv, path_sv, atime_sv, mtime_sv, cb);

void
_async_chmod (SV* self_sv, SV* path_sv, SV* mode_sv, SV* cb)
    ALIAS:
        _async_lchmod = 1
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);
        int mode = SvIV(mode_sv);   // TODO

        const char* funcname = ix ? "lchmod" : "chmod";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_fallible_empty_return, NULL);

        int err;

        if (ix) {
            err = nfs_lchmod_async(perl_nfs->nfs, path, mode, _do_perl_callback, cb_sp);
        }
        else {
            err = nfs_chmod_async(perl_nfs->nfs, path, mode, _do_perl_callback, cb_sp);
        }

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

SV*
truncate (SV* self_sv, SV* path_sv, SV* length_sv)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);
        uint64_t len = exs_SvUV(length_sv);   // TODO

        int err = nfs_truncate(perl_nfs->nfs, path, len);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "truncate", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_truncate (SV* self_sv, SV* path_sv, SV* length_sv, SV* cb)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);
        uint64_t len = exs_SvUV(length_sv);   // TODO

        const char* funcname = "truncate";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_fallible_empty_return, NULL);

        int err = nfs_truncate_async(perl_nfs->nfs, path, len, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

SV*
chown (SV* self_sv, SV* path_sv, SV* uid_sv, SV* gid_sv)
    ALIAS:
        lchown = 1
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        int uid = SvIV(uid_sv);   // TODO
        int gid = SvIV(gid_sv);   // TODO

        int err;

        if (ix) {
            err = nfs_lchown(perl_nfs->nfs, path, uid, gid);
        }
        else {
            err = nfs_chown(perl_nfs->nfs, path, uid, gid);
        }

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, ix ? "lchown" : "chown", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_chown (SV* self_sv, SV* path_sv, SV* uid_sv, SV* gid_sv, SV* cb)
    ALIAS:
        _async_lchown = 1
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* path = exs_SvPVbyte_nolen(path_sv);

        int uid = SvIV(uid_sv);   // TODO
        int gid = SvIV(gid_sv);   // TODO

        const char* funcname = ix ? "lchown" : "chown";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_fallible_empty_return, NULL);

        int err;

        if (ix) {
            err = nfs_lchown_async(perl_nfs->nfs, path, uid, gid, _do_perl_callback, cb_sp);
        }
        else {
            err = nfs_chown_async(perl_nfs->nfs, path, uid, gid, _do_perl_callback, cb_sp);
        }

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

SV*
symlink (SV* self_sv, SV* old_sv, SV* new_sv)
    ALIAS:
        rename = 1
        link = 2
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* oldname = exs_SvPVbyte_nolen(old_sv);
        const char* newname = exs_SvPVbyte_nolen(new_sv);

        int err;

        _nfs_void_2pathfunc func = VOID_2PATHFUNC_BY_IX[ix];

        err = func(perl_nfs->nfs, oldname, newname);

        if (err) {
            const char *funcname = VOID_2PATHFUNC_NAME_BY_IX[ix];

            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_symlink (SV* self_sv, SV* old_sv, SV* new_sv, SV* cb)
    ALIAS:
        _async_rename = 1
        _async_link = 2
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);

        const char* oldname = exs_SvPVbyte_nolen(old_sv);
        const char* newname = exs_SvPVbyte_nolen(new_sv);

        _nfs_async_void_2pathfunc func = ASYNC_VOID_2PATHFUNC_BY_IX[ix];

        const char *funcname = VOID_2PATHFUNC_NAME_BY_IX[ix];

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_fallible_empty_return, NULL);

        int err = func(perl_nfs->nfs, oldname, newname, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

# ----------------------------------------------------------------------
# Async-oriented stuff

int
_get_fd (SV* self_sv)
    ALIAS:
        _which_events = 1
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);
        struct nfs_context *nfs = perl_nfs->nfs;

        RETVAL = ix ? nfs_which_events(nfs) : nfs_get_fd(nfs);
    OUTPUT:
        RETVAL

int
_service (SV* self_sv, int revents)
    CODE:
        nlnfs_s* perl_nfs = exs_structref_ptr(self_sv);
        struct nfs_context *nfs = perl_nfs->nfs;

        RETVAL = nfs_service(nfs, revents);

    OUTPUT:
        RETVAL


# ----------------------------------------------------------------------
# This class is here for mount_getexports_async:

MODULE = Net::LibNFS        PACKAGE = Net::LibNFS::RPC

PROTOTYPES: DISABLE

SV*
new (const char* classname)
    CODE:
        struct rpc_context *rpc = rpc_init_context();
        if (NULL == rpc) {
            croak("Failed to init libnfs rpc context");
        }

        RETVAL = exs_new_structref(nlnfs_rpc_s, classname);
        nlnfs_rpc_s* perl_rpc = exs_structref_ptr(RETVAL);

        *perl_rpc = (nlnfs_rpc_s) {
            .rpc = rpc,
            .pid = getpid(),
        };

    OUTPUT:
        RETVAL

void
DESTROY (SV* self_sv)
    CODE:
        nlnfs_rpc_s* perl_rpc = exs_structref_ptr(self_sv);

        assert(perl_rpc);

        if (perl_rpc->pid == getpid() && PL_dirty) {
            warn("%" SVf ": DESTROY at global destruction; memory leak likely!\n", self_sv);
        }

        assert(perl_rpc->rpc);

        rpc_destroy_context(perl_rpc->rpc);

void
_async_mount_getexports (SV* self_sv, SV* server_sv, SV* cb)
    CODE:
        nlnfs_rpc_s* perl_rpc = exs_structref_ptr(self_sv);

        struct rpc_context* rpc = perl_rpc->rpc;

        const char* server = exs_SvPVbyte_nolen(server_sv);

        const char* funcname = "mount_getexports";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_mount_getexports, NULL);

        int err = mount_getexports_async(rpc, server, _do_perl_rpc_callback, cb_sp);

        if (err) {
            const char* str = rpc_get_error(rpc);
            croak_sv( _create_rpc_errno(aTHX_ rpc, funcname, err, str) );
        }

int
_get_fd (SV* self_sv)
    ALIAS:
        _which_events = 1
    CODE:
        nlnfs_rpc_s* perl_rpc = exs_structref_ptr(self_sv);
        struct rpc_context *rpc = perl_rpc->rpc;

        RETVAL = ix ? rpc_which_events(rpc) : rpc_get_fd(rpc);
    OUTPUT:
        RETVAL

int
_service (SV* self_sv, int revents)
    CODE:
        nlnfs_rpc_s* perl_rpc = exs_structref_ptr(self_sv);
        struct rpc_context *rpc = perl_rpc->rpc;

        RETVAL = rpc_service(rpc, revents);

    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

MODULE = Net::LibNFS        PACKAGE = Net::LibNFS::Dirhandle

PROTOTYPES: DISABLE

void
DESTROY (SV* self_sv)
    CODE:
        nlnfs_dh_s* nfs_dh = exs_structref_ptr(self_sv);

        if (!nfs_dh->closed) {
            SV* nfs_sv = nfs_dh->perl_nfs;

            nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

            nfs_closedir( perl_nfs->nfs, nfs_dh->nfsdh );
        }

        SvREFCNT_dec(nfs_dh->perl_nfs);

void
read (SV* self_sv)
    PPCODE:
        _FORBID_VOID_CONTEXT;

        nlnfs_dh_s* nfs_dh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_dh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        unsigned retcount = 0;
        struct nfsdirent* dent = nfs_readdir( perl_nfs->nfs, nfs_dh->nfsdh );
        struct nfsdirent* cur_dent = dent;

        while (cur_dent) {
            retcount++;
            if (GIMME_V != G_ARRAY) break;

            cur_dent = cur_dent->next;
        }

        if (retcount) {
            EXTEND(SP, retcount);

            unsigned retcount_copy = retcount;

            while (1) {
                mPUSHs(_ptr_to_perl_dirent_obj(aTHX_ dent));

                retcount_copy--;
                if (!retcount_copy) break;

                dent = nfs_readdir( perl_nfs->nfs, nfs_dh->nfsdh );
            }
        }

        XSRETURN(retcount);

SV*
seek (SV* self_sv, SV* loc_sv)
    CODE:
        nlnfs_dh_s* nfs_dh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_dh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        long loc = SvIV(loc_sv);    // TODO

        nfs_seekdir( perl_nfs->nfs, nfs_dh->nfsdh, loc );

        RETVAL = SvREFCNT_inc(self_sv);

    OUTPUT:
        RETVAL

long
tell (SV* self_sv)
    CODE:
        nlnfs_dh_s* nfs_dh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_dh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        RETVAL = nfs_telldir( perl_nfs->nfs, nfs_dh->nfsdh );

        if (RETVAL < 0) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "telldir", RETVAL, NULL);
        }

    OUTPUT:
        RETVAL

SV*
rewind (SV* self_sv)
    ALIAS:
        close = 1
    CODE:
        nlnfs_dh_s* nfs_dh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_dh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        if (ix) {
            if (!nfs_dh->closed) {
                nfs_closedir( perl_nfs->nfs, nfs_dh->nfsdh );
                nfs_dh->closed = true;
            }
        }
        else {
            nfs_rewinddir( perl_nfs->nfs, nfs_dh->nfsdh );
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

MODULE = Net::LibNFS        PACKAGE = Net::LibNFS::Filehandle

PROTOTYPES: DISABLE

void
DESTROY (SV* self_sv)
    CODE:
        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SvREFCNT_dec(nfs_fh->perl_nfs);

void
close (SV* self_sv)
    PPCODE:
        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        int err = nfs_close(perl_nfs->nfs, nfs_fh->nfsfh);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "close", err, NULL);
        }

        XSRETURN_EMPTY;

void
_async_close (SV* self_sv, SV* cb)
    ALIAS:
        _async_sync = 1
    CODE:
        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        const char* funcname = ix ? "sync" : "close";

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ funcname, cb, _parse_fallible_empty_return, NULL);

        int err;

        if (ix) {
            err = nfs_fsync_async(perl_nfs->nfs, nfs_fh->nfsfh, _do_perl_callback, cb_sp);
        }
        else {
            err = nfs_close_async(perl_nfs->nfs, nfs_fh->nfsfh, _do_perl_callback, cb_sp);
        }

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, funcname, err, NULL);
        }

SV*
read (SV* self_sv, SV* count_sv)
    CODE:
        RETVAL = _read_or_pread(aTHX_ self_sv, NULL, count_sv, NULL);
    OUTPUT:
        RETVAL

void
_async_read (SV* self_sv, SV* count_sv, SV* cb)
    CODE:
        _read_or_pread(aTHX_ self_sv, NULL, count_sv, cb);

SV*
pread (SV* self_sv, SV* offset_sv, SV* count_sv)
    CODE:
        RETVAL = _read_or_pread(aTHX_ self_sv, offset_sv, count_sv, NULL);
    OUTPUT:
        RETVAL

void
_async_pread (SV* self_sv, SV* offset_sv, SV* count_sv, SV* cb)
    CODE:
        _read_or_pread(aTHX_ self_sv, offset_sv, count_sv, cb);

SV*
stat (SV* self_sv)
    CODE:
        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        struct nfs_stat_64 st;

        int err = nfs_fstat64(perl_nfs->nfs, nfs_fh->nfsfh, &st);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "stat", err, NULL);
        }

        RETVAL = _ptr_to_perl_stat_obj(aTHX_ &st);

    OUTPUT:
        RETVAL

void
_async_stat (SV* self_sv, SV* cb)
    CODE:
        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "stat", cb, _parse_stat64_async, NULL);

        int err = nfs_fstat64_async(perl_nfs->nfs, nfs_fh->nfsfh, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "stat", err, NULL);
        }

int
write (SV* self_sv, SV* buf_sv)
    CODE:
        RETVAL = _write_or_pwrite(aTHX_ self_sv, NULL, buf_sv, NULL);

    OUTPUT:
        RETVAL

void
_async_write (SV* self_sv, SV* buf_sv, SV* cb)
    CODE:
        _write_or_pwrite(aTHX_ self_sv, NULL, buf_sv, cb);

int
pwrite (SV* self_sv, SV* offset_sv, SV* buf_sv)
    CODE:
        RETVAL = _write_or_pwrite(aTHX_ self_sv, offset_sv, buf_sv, NULL);

    OUTPUT:
        RETVAL

void
_async_pwrite (SV* self_sv, SV* offset_sv, SV* buf_sv, SV* cb)
    CODE:
        _write_or_pwrite(aTHX_ self_sv, offset_sv, buf_sv, cb);

uint64_t
seek (SV* self_sv, SV* offset_sv, SV* whence_sv)
    CODE:
        int64_t offset = SvIV(offset_sv);   // TODO: strict
        int whence = SvIV(whence_sv);

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        uint64_t current_offset;
        int err = nfs_lseek(perl_nfs->nfs, nfs_fh->nfsfh, offset, whence, &current_offset);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "lseek", err, NULL);
        }

        RETVAL = current_offset;

    OUTPUT:
        RETVAL

void
_async_seek (SV* self_sv, SV* offset_sv, SV* whence_sv, SV* cb)
    CODE:
        int64_t offset = SvIV(offset_sv);   // TODO: strict
        int whence = SvIV(whence_sv);

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "seek", cb, _parse_lseek_async, NULL);

        int err = nfs_lseek_async(perl_nfs->nfs, nfs_fh->nfsfh, offset, whence, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "seek", err, NULL);
        }

SV*
fcntl (SV* self_sv, SV* cmd_sv, ...)
    CODE:
        enum nfs4_fcntl_op cmd = exs_SvUV(cmd_sv);

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        union fcntl_arg arg;

        _set_fcntl_arg(aTHX_ cmd, &arg, &ST(2), items - 2);

        int err = nfs_fcntl(perl_nfs->nfs, nfs_fh->nfsfh, cmd, &arg);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "fcntl", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_fcntl (SV* self_sv, SV* cmd_sv, ...)
    CODE:
        enum nfs4_fcntl_op cmd = exs_SvUV(cmd_sv);

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        union fcntl_arg arg;

        _set_fcntl_arg(aTHX_ cmd, &arg, &ST(2), items - 3);

        SV* cb = ST(items - 1);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "fcntl", cb, _parse_fallible_empty_return, NULL);

        int err = nfs_fcntl_async(perl_nfs->nfs, nfs_fh->nfsfh, cmd, &arg, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "fcntl", err, NULL);
        }

SV*
sync (SV* self_sv)
    CODE:
        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        int err = nfs_fsync(perl_nfs->nfs, nfs_fh->nfsfh);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "fsync", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

# NB: _async_sync is defined as an alias.

SV*
truncate (SV* self_sv, SV* length_sv)
    CODE:
        uint64_t len = exs_SvUV(length_sv);

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        int err = nfs_ftruncate(perl_nfs->nfs, nfs_fh->nfsfh, len);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "ftruncate", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_truncate (SV* self_sv, SV* length_sv, SV* cb)
    CODE:
        uint64_t len = exs_SvUV(length_sv);

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "truncate", cb, _parse_fallible_empty_return, NULL);

        int err = nfs_ftruncate_async(perl_nfs->nfs, nfs_fh->nfsfh, len, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "truncate", err, NULL);
        }

SV*
chmod (SV* self_sv, SV* mode_sv)
    CODE:
        int mode = SvIV(mode_sv);   // TODO

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        int err = nfs_fchmod(perl_nfs->nfs, nfs_fh->nfsfh, mode);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "fchmod", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_chmod (SV* self_sv, SV* mode_sv, SV* cb)
    CODE:
        int mode = SvIV(mode_sv);   // TODO

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "chmod", cb, _parse_fallible_empty_return, NULL);

        int err = nfs_fchmod_async(perl_nfs->nfs, nfs_fh->nfsfh, mode, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "chmod", err, NULL);
        }

SV*
chown (SV* self_sv, SV* uid_sv, SV* gid_sv)
    CODE:
        int uid = SvIV(uid_sv);   // TODO
        int gid = SvIV(gid_sv);   // TODO

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        int err = nfs_fchown(perl_nfs->nfs, nfs_fh->nfsfh, uid, gid);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "fchown", err, NULL);
        }

        RETVAL = SvREFCNT_inc(self_sv);
    OUTPUT:
        RETVAL

void
_async_chown (SV* self_sv, SV* uid_sv, SV* gid_sv, SV* cb)
    CODE:
        int uid = SvIV(uid_sv);   // TODO
        int gid = SvIV(gid_sv);   // TODO

        nlnfs_fh_s* nfs_fh = exs_structref_ptr(self_sv);

        SV* nfs_sv = nfs_fh->perl_nfs;

        nlnfs_s* perl_nfs = exs_structref_ptr(nfs_sv);

        perl_cb_s* cb_sp = _create_callback_struct(aTHX_ "chown", cb, _parse_fallible_empty_return, NULL);

        int err = nfs_fchown_async(perl_nfs->nfs, nfs_fh->nfsfh, uid, gid, _do_perl_callback, cb_sp);

        if (err) {
            _croak_nfs_errno(aTHX_ perl_nfs->nfs, "chown", err, NULL);
        }

# ----------------------------------------------------------------------

MODULE = Net::LibNFS        PACKAGE = Net::LibNFS::Stat

PROTOTYPES: DISABLE

UV
dev (SV* self_sv)
    ALIAS:
        ino = 1
        mode = 2
        nlink = 3
        uid = 4
        gid = 5
        rdev = 6
        size = 7
        blksize = 8
        blocks = 9
        atime = 10
        mtime = 11
        ctime = 12
        atime_nsec = 13
        mtime_nsec = 14
        ctime_nsec = 15
        nfs_used = 16
    CODE:
        struct nfs_stat_64* stat_p = exs_structref_ptr(self_sv);
        RETVAL = *( (uint64_t*) ((void*)(stat_p) + STAT64_OFFSET[ix]) );
    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

MODULE = Net::LibNFS        PACKAGE = Net::LibNFS::StatVFS

PROTOTYPES: DISABLESTATVFS64_OFFSET

UV
bsize (SV* self_sv)
    ALIAS:
        frsize = 1
        blocks = 2
        bfree = 3
        bavail = 4
        files = 5
        ffree = 6
        favail = 7
        fsid = 8
        flag = 9
        namemax = 10
    CODE:
        struct nfs_statvfs_64* p = exs_structref_ptr(self_sv);
        RETVAL = *( (uint64_t*) ((void*)(p) + STATVFS64_OFFSET[ix]) );
    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

MODULE = Net::LibNFS        PACKAGE = Net::LibNFS::DirEnt

PROTOTYPES: DISABLE

SV*
next (SV* self_sv)
    CODE:
        struct nfsdirent* p = exs_structref_ptr(self_sv);
        RETVAL = p->next ? exs_new_structref(struct nfsdirent, PERL_DIRENT_NS) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV*
name (SV* self_sv)
    CODE:
        struct nfsdirent* p = exs_structref_ptr(self_sv);
        RETVAL = newSVpv(p->name, 0);
    OUTPUT:
        RETVAL

# ix offset by 2
uint64_t
inode (SV* self_sv)
    ALIAS:
        size = 3
        dev = 10
        rdev = 11
        blksize = 12
        blocks = 13
        used = 14
    CODE:
        struct nfsdirent* p = exs_structref_ptr(self_sv);
        RETVAL = *( (uint64_t*) ((void*)(p) + DIRENT_OFFSET[2 + ix]) );
    OUTPUT:
        RETVAL

# ix offset by 3
uint32_t
type (SV* self_sv)
    ALIAS:
        mode = 1
        uid = 6
        gid = 7
        nlink = 8
        atime_nsec = 13
        mtime_nsec = 14
        ctime_nsec = 15
    CODE:
        struct nfsdirent* p = exs_structref_ptr(self_sv);
        RETVAL = *( (uint32_t*) ((void*)(p) + DIRENT_OFFSET[3 + ix]) );
    OUTPUT:
        RETVAL

# ix offset by 6
NV
atime (SV* self_sv)
    ALIAS:
        mtime = 1
        ctime = 2
    CODE:
        struct nfsdirent* p = exs_structref_ptr(self_sv);
        struct timeval* tval_p = ((void*)(p) + DIRENT_OFFSET[6 + ix]);

        RETVAL = tval_p->tv_sec + (tval_p->tv_usec / 1000000);
    OUTPUT:
        RETVAL
