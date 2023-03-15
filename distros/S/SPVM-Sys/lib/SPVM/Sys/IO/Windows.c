#include "spvm_native.h"

static const char* FILE_NAME = "Sys/IO/Windows.c";

#if defined(_WIN32)

// These implementations are originally copied form Perl win32/win32.c and win32/win32.h

#include <unistd.h>
#include <windows.h>
#include <errno.h>
#include <winbase.h>

#ifndef EDQUOT			/* Not in errno.h but wanted by POSIX.pm */
#  define EDQUOT		WSAEDQUOT
#endif

#define PerlDir_mapA(file) file
#define dTHX 
#define bool BOOL
#define strEQ(string1, string2) (strcmp(string1, string2) == 0)
#define isSLASH(c) ((c) == '/' || (c) == '\\')

#define savepv(string) ((char*)env->get_chars(env, stack, env->new_string(env, stack, string, strlen(string))))

#define SAVEFREEPV(pv) ((void*)NULL)

static OSVERSIONINFO g_osver = {0, 0, 0, 0, 0, ""};

typedef BOOLEAN (__stdcall *pCreateSymbolicLinkA_t)(LPCSTR, LPCSTR, DWORD);

#ifndef SYMBOLIC_LINK_FLAG_DIRECTORY
#  define SYMBOLIC_LINK_FLAG_DIRECTORY 0x1
#endif

#ifndef SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
#  define SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE 0x2
#endif

typedef struct {
    USHORT SubstituteNameOffset;
    USHORT SubstituteNameLength;
    USHORT PrintNameOffset;
    USHORT PrintNameLength;
    ULONG  Flags;
    WCHAR  PathBuffer[MAX_PATH*3];
} MY_SYMLINK_REPARSE_BUFFER, *PMY_SYMLINK_REPARSE_BUFFER;

typedef struct {
    USHORT SubstituteNameOffset;
    USHORT SubstituteNameLength;
    USHORT PrintNameOffset;
    USHORT PrintNameLength;
    WCHAR  PathBuffer[MAX_PATH*3];
} MY_MOUNT_POINT_REPARSE_BUFFER;

typedef struct {
  ULONG  ReparseTag;
  USHORT ReparseDataLength;
  USHORT Reserved;
  union {
    MY_SYMLINK_REPARSE_BUFFER SymbolicLinkReparseBuffer;
    MY_MOUNT_POINT_REPARSE_BUFFER MountPointReparseBuffer;
    struct {
      UCHAR DataBuffer[1];
    } GenericReparseBuffer;
  } Data;
} MY_REPARSE_DATA_BUFFER, *PMY_REPARSE_DATA_BUFFER;

static BOOL
is_symlink(HANDLE h) {
    MY_REPARSE_DATA_BUFFER linkdata;
    const MY_SYMLINK_REPARSE_BUFFER * const sd =
        &linkdata.Data.SymbolicLinkReparseBuffer;
    DWORD linkdata_returned;

    if (!DeviceIoControl(h, FSCTL_GET_REPARSE_POINT, NULL, 0, &linkdata, sizeof(linkdata), &linkdata_returned, NULL)) {
        return FALSE;
    }

    if (linkdata_returned < offsetof(MY_REPARSE_DATA_BUFFER, Data.SymbolicLinkReparseBuffer.PathBuffer)
        || (linkdata.ReparseTag != IO_REPARSE_TAG_SYMLINK
            && linkdata.ReparseTag != IO_REPARSE_TAG_MOUNT_POINT)) {
        /* some other type of reparse point */
        return FALSE;
    }

    return TRUE;
}

static BOOL
is_symlink_name(const char *name) {
    HANDLE f = CreateFileA(name, GENERIC_READ, 0, NULL, OPEN_EXISTING,
                           FILE_FLAG_OPEN_REPARSE_POINT|FILE_FLAG_BACKUP_SEMANTICS, 0);
    BOOL result;

    if (f == INVALID_HANDLE_VALUE) {
        return FALSE;
    }
    result = is_symlink(f);
    CloseHandle(f);

    return result;
}

static int
win32_unlink(const char *filename)
{
    dTHX;
    int ret;
    DWORD attrs;

    filename = PerlDir_mapA(filename);
    attrs = GetFileAttributesA(filename);
    if (attrs == 0xFFFFFFFF) {
        errno = ENOENT;
        return -1;
    }
    if (attrs & FILE_ATTRIBUTE_READONLY) {
        (void)SetFileAttributesA(filename, attrs & ~FILE_ATTRIBUTE_READONLY);
        ret = unlink(filename);
        if (ret == -1)
            (void)SetFileAttributesA(filename, attrs);
    }
    else if ((attrs & (FILE_ATTRIBUTE_REPARSE_POINT | FILE_ATTRIBUTE_DIRECTORY))
        == (FILE_ATTRIBUTE_REPARSE_POINT | FILE_ATTRIBUTE_DIRECTORY)
             && is_symlink_name(filename)) {
        ret = rmdir(filename);
    }
    else {
        ret = unlink(filename);
    }
    return ret;
}

static int
win32_rename(const char *oname, const char *newname)
{
    char szOldName[MAX_PATH+1];
    BOOL bResult;
    DWORD dwFlags = MOVEFILE_COPY_ALLOWED;
    dTHX;

    if (stricmp(newname, oname))
        dwFlags |= MOVEFILE_REPLACE_EXISTING;
    strcpy(szOldName, PerlDir_mapA(oname));

    bResult = MoveFileExA(szOldName,PerlDir_mapA(newname), dwFlags);
    if (!bResult) {
        DWORD err = GetLastError();
        switch (err) {
        case ERROR_BAD_NET_NAME:
        case ERROR_BAD_NETPATH:
        case ERROR_BAD_PATHNAME:
        case ERROR_FILE_NOT_FOUND:
        case ERROR_FILENAME_EXCED_RANGE:
        case ERROR_INVALID_DRIVE:
        case ERROR_NO_MORE_FILES:
        case ERROR_PATH_NOT_FOUND:
            errno = ENOENT;
            break;
        case ERROR_DISK_FULL:
            errno = ENOSPC;
            break;
        case ERROR_NOT_ENOUGH_QUOTA:
            errno = EDQUOT;
            break;
        default:
            errno = EACCES;
            break;
        }
        return -1;
    }
    return 0;
}

static void
translate_to_errno(void)
{
    /* This isn't perfect, eg. Win32 returns ERROR_ACCESS_DENIED for
       both permissions errors and if the source is a directory, while
       POSIX wants EACCES and EPERM respectively.
    */
    switch (GetLastError()) {
    case ERROR_BAD_NET_NAME:
    case ERROR_BAD_NETPATH:
    case ERROR_BAD_PATHNAME:
    case ERROR_FILE_NOT_FOUND:
    case ERROR_FILENAME_EXCED_RANGE:
    case ERROR_INVALID_DRIVE:
    case ERROR_PATH_NOT_FOUND:
      errno = ENOENT;
      break;
    case ERROR_ALREADY_EXISTS:
      errno = EEXIST;
      break;
    case ERROR_ACCESS_DENIED:
      errno = EACCES;
      break;
    case ERROR_PRIVILEGE_NOT_HELD:
      errno = EPERM;
      break;
    case ERROR_NOT_SAME_DEVICE:
      errno = EXDEV;
      break;
    case ERROR_DISK_FULL:
      errno = ENOSPC;
      break;
    case ERROR_NOT_ENOUGH_QUOTA:
      errno = EDQUOT;
      break;
    default:
      /* ERROR_INVALID_FUNCTION - eg. symlink on a FAT volume */
      errno = EINVAL;
      break;
    }
}

static int
do_readlink_handle(HANDLE hlink, char *buf, size_t bufsiz, bool *is_symlink) {
    MY_REPARSE_DATA_BUFFER linkdata;
    DWORD linkdata_returned;

    if (is_symlink)
        *is_symlink = FALSE;

    if (!DeviceIoControl(hlink, FSCTL_GET_REPARSE_POINT, NULL, 0, &linkdata, sizeof(linkdata), &linkdata_returned, NULL)) {
        translate_to_errno();
        return -1;
    }

    int bytes_out;
    BOOL used_default;
    switch (linkdata.ReparseTag) {
    case IO_REPARSE_TAG_SYMLINK:
        {
            const MY_SYMLINK_REPARSE_BUFFER * const sd =
                &linkdata.Data.SymbolicLinkReparseBuffer;
            if (linkdata_returned < offsetof(MY_REPARSE_DATA_BUFFER, Data.SymbolicLinkReparseBuffer.PathBuffer)) {
                errno = EINVAL;
                return -1;
            }
            bytes_out =
                WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS,
                                    sd->PathBuffer + sd->PrintNameOffset/2,
                                    sd->PrintNameLength/2,
                                    buf, (int)bufsiz, NULL, &used_default);
            if (is_symlink)
                *is_symlink = TRUE;
        }
        break;
    case IO_REPARSE_TAG_MOUNT_POINT:
        {
            const MY_MOUNT_POINT_REPARSE_BUFFER * const rd =
                &linkdata.Data.MountPointReparseBuffer;
            if (linkdata_returned < offsetof(MY_REPARSE_DATA_BUFFER, Data.MountPointReparseBuffer.PathBuffer)) {
                errno = EINVAL;
                return -1;
            }
            bytes_out =
                WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS,
                                    rd->PathBuffer + rd->PrintNameOffset/2,
                                    rd->PrintNameLength/2,
                                    buf, (int)bufsiz, NULL, &used_default);
            if (is_symlink)
                *is_symlink = TRUE;
        }
        break;

    default:
        errno = EINVAL;
        return -1;
    }

    if (bytes_out == 0 || used_default) {
        /* failed conversion from unicode to ANSI or otherwise failed */
        errno = EINVAL;
        return -1;
    }

    return bytes_out;
}

static int
win32_readlink(const char *pathname, char *buf, size_t bufsiz) {
    if (pathname == NULL || buf == NULL) {
        errno = EFAULT;
        return -1;
    }
    if (bufsiz <= 0) {
        errno = EINVAL;
        return -1;
    }

    DWORD fileattr = GetFileAttributes(pathname);
    if (fileattr == INVALID_FILE_ATTRIBUTES) {
        translate_to_errno();
        return -1;
    }

    if (!(fileattr & FILE_ATTRIBUTE_REPARSE_POINT)) {
        /* not a symbolic link */
        errno = EINVAL;
        return -1;
    }

    HANDLE hlink =
        CreateFileA(pathname, GENERIC_READ, 0, NULL, OPEN_EXISTING,
                    FILE_FLAG_OPEN_REPARSE_POINT|FILE_FLAG_BACKUP_SEMANTICS, 0);
    if (hlink == INVALID_HANDLE_VALUE) {
        translate_to_errno();
        return -1;
    }
    int bytes_out = do_readlink_handle(hlink, buf, bufsiz, NULL);
    CloseHandle(hlink);
    if (bytes_out < 0) {
        /* errno already set */
        return -1;
    }

    if ((size_t)bytes_out > bufsiz) {
        errno = EINVAL;
        return -1;
    }

    return bytes_out;
}

static int
win32_get_readlink_buffer_size(const char *pathname) {
    DWORD fileattr = GetFileAttributes(pathname);
    if (fileattr == INVALID_FILE_ATTRIBUTES) {
        translate_to_errno();
        return -1;
    }

    if (!(fileattr & FILE_ATTRIBUTE_REPARSE_POINT)) {
        /* not a symbolic link */
        errno = EINVAL;
        return -1;
    }

    HANDLE hlink =
        CreateFileA(pathname, GENERIC_READ, 0, NULL, OPEN_EXISTING,
                    FILE_FLAG_OPEN_REPARSE_POINT|FILE_FLAG_BACKUP_SEMANTICS, 0);
    if (hlink == INVALID_HANDLE_VALUE) {
        translate_to_errno();
        return -1;
    }
    int bytes_out = do_readlink_handle(hlink, NULL, 0, NULL);
    CloseHandle(hlink);
    if (bytes_out < 0) {
        /* errno already set */
        return -1;
    }

    return bytes_out;
}

int
win32_symlink(SPVM_ENV* env, SPVM_VALUE* stack, const char *oldfile, const char *newfile)
{
    dTHX;
    size_t oldfile_len = strlen(oldfile);
    pCreateSymbolicLinkA_t pCreateSymbolicLinkA =
        (pCreateSymbolicLinkA_t)GetProcAddress(GetModuleHandle("kernel32.dll"), "CreateSymbolicLinkA");
    DWORD create_flags = 0;

    /* this flag can be used only on Windows 10 1703 or newer */
    if (g_osver.dwMajorVersion > 10 ||
        (g_osver.dwMajorVersion == 10 &&
         (g_osver.dwMinorVersion > 0 || g_osver.dwBuildNumber > 15063)))
    {
        create_flags |= SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
    }

    if (!pCreateSymbolicLinkA) {
        errno = ENOSYS;
        return -1;
    }

    /* oldfile might be relative and we don't want to change that,
       so don't map that.
    */
    newfile = PerlDir_mapA(newfile);

    if (strchr(oldfile, '/')) {
        /* Win32 (or perhaps NTFS) won't follow symlinks containing
           /, so replace any with \\
        */
        char *temp = savepv(oldfile);
        SAVEFREEPV(temp);
        char *p = temp;
        while (*p) {
            if (*p == '/') {
                *p = '\\';
            }
            ++p;
        }
        *p = 0;
        oldfile = temp;
        oldfile_len = p - temp;
    }

    /* are we linking to a directory?
       CreateSymlinkA() needs to know if the target is a directory,
       If it looks like a directory name:
        - ends in slash
        - is just . or ..
        - ends in /. or /.. (with either slash)
        - is a simple drive letter
       assume it's a directory.
       Otherwise if the oldfile is relative we need to make a relative path
       based on the newfile to check if the target is a directory.
    */
    if ((oldfile_len >= 1 && isSLASH(oldfile[oldfile_len-1])) ||
        strEQ(oldfile, "..") ||
        strEQ(oldfile, ".") ||
        (isSLASH(oldfile[oldfile_len-2]) && oldfile[oldfile_len-1] == '.') ||
        strEQ(oldfile+oldfile_len-3, "\\..") ||
        (oldfile_len == 2 && oldfile[1] == ':')) {
        create_flags |= SYMBOLIC_LINK_FLAG_DIRECTORY;
    }
    else {
        DWORD dest_attr;
        const char *dest_path = oldfile;
        char szTargetName[MAX_PATH+1];

        if (oldfile_len >= 3 && oldfile[1] == ':') {
            /* relative to current directory on a drive, or absolute */
            /* dest_path = oldfile; already done */
        }
        else if (oldfile[0] != '\\') {
            size_t newfile_len = strlen(newfile);
            char *last_slash = strrchr(newfile, '/');
            char *last_bslash = strrchr(newfile, '\\');
            char *end_dir = last_slash && last_bslash
                ? ( last_slash > last_bslash ? last_slash : last_bslash)
                : last_slash ? last_slash : last_bslash ? last_bslash : NULL;

            if (end_dir) {
                if ((end_dir - newfile + 1) + oldfile_len > MAX_PATH) {
                    /* too long */
                    errno = EINVAL;
                    return -1;
                }

                memcpy(szTargetName, newfile, end_dir - newfile + 1);
                strcpy(szTargetName + (end_dir - newfile + 1), oldfile);
                dest_path = szTargetName;
            }
            else {
                /* newpath is just a filename */
                /* dest_path = oldfile; */
            }
        }

        dest_attr = GetFileAttributes(dest_path);
        if (dest_attr != (DWORD)-1 && (dest_attr & FILE_ATTRIBUTE_DIRECTORY)) {
            create_flags |= SYMBOLIC_LINK_FLAG_DIRECTORY;
        }
    }

    if (!pCreateSymbolicLinkA(newfile, oldfile, create_flags)) {
        translate_to_errno();
        return -1;
    }

    return 0;
}

#endif // _WIN32

int32_t SPVM__Sys__IO__Windows__is_symlink(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "The $path must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  const char* path = env->get_chars(env, stack, obj_path);
  
  int32_t success = is_symlink_name(path);
  
  stack[0].ival = success;
  
  return 0;

#else

  return env->die(env, stack, "This method is not supported on this os(!defined(_WIN32))", __func__, FILE_NAME, __LINE__);

#endif

}

int32_t SPVM__Sys__IO__Windows__unlink(SPVM_ENV* env, SPVM_VALUE* stack) {
  
#if defined(_WIN32)
  void* obj_pathname = stack[0].oval;
  if (!obj_pathname) {
    return env->die(env, stack, "The $pathname must be defined", __func__, FILE_NAME, __LINE__);
  }
  
  const char* pathname = env->get_chars(env, stack, obj_pathname);
  
  int32_t status = win32_unlink(pathname);
  
  stack[0].ival = status;
  if (status == -1) {
    env->die(env, stack, "[System Error]unlink failed:%s. The \"%s\" file can't be removed", env->strerror(env, stack, errno, 0), pathname, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  return 0;

#else

  return env->die(env, stack, "This method is not supported on this os(!defined(_WIN32))", __func__, FILE_NAME, __LINE__);

#endif

}

int32_t SPVM__Sys__IO__Windows__rename(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(_WIN32)
  void* obj_oldpath = stack[0].oval;
  if (!obj_oldpath) {
    return env->die(env, stack, "The $oldpath must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* oldpath = env->get_chars(env, stack, obj_oldpath);
  
  void* obj_newpath = stack[0].oval;
  if (!obj_newpath) {
    return env->die(env, stack, "The $newpath must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* newpath = env->get_chars(env, stack, obj_newpath);
  
  int32_t status = win32_rename(oldpath, newpath);
  if (status == -1) {
    env->die(env, stack, "[System Error]rename failed:%s. The \"%s\" file can't be renamed to the \"%s\" file", env->strerror(env, stack, errno, 0), oldpath, newpath, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;

#else

  return env->die(env, stack, "This method is not supported on this os(!defined(_WIN32))", __func__, FILE_NAME, __LINE__);

#endif

}

int32_t SPVM__Sys__IO__Windows__readlink(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(_WIN32)
  int32_t e = 0;
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "The $path must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);

  void* obj_buf = stack[1].oval;
  if (!obj_buf) {
    return env->die(env, stack, "The $buf must be defined", __func__, FILE_NAME, __LINE__);
  }
  char* buf = (char*)env->get_chars(env, stack, obj_buf);
  int32_t buf_length = env->length(env, stack, obj_buf);
  
  int32_t bufsiz = stack[2].ival;
  if (!(bufsiz >= 0)) {
    return env->die(env, stack, "The $bufsiz must be greater than or equal to 0", __func__, FILE_NAME, __LINE__);
  }
  if (!(bufsiz <= buf_length)) {
    return env->die(env, stack, "The $bufsiz must be less than or equal to the length of the $buf", __func__, FILE_NAME, __LINE__);
  }
  
  errno = 0;
  int32_t placed_length = win32_readlink(path, buf, bufsiz);
  if (placed_length == -1) {
    env->die(env, stack, "[System Error]readlink failed:%s. The reading of the symbolic link of the \"%s\" file failed", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = placed_length;
  
  return 0;

#else

  return env->die(env, stack, "This method is not supported on this os(!defined(_WIN32))", __func__, FILE_NAME, __LINE__);

#endif

}

int32_t SPVM__Sys__IO__Windows__get_readlink_buffer_size(SPVM_ENV* env, SPVM_VALUE* stack) {

#if defined(_WIN32)
  int32_t e = 0;
  
  void* obj_path = stack[0].oval;
  if (!obj_path) {
    return env->die(env, stack, "The $path must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* path = env->get_chars(env, stack, obj_path);

  errno = 0;
  int32_t placed_length = win32_get_readlink_buffer_size(path);
  if (placed_length < 0) {
    env->die(env, stack, "[System Error]win32_get_readlink_buffer_size failed:%s. The reading of the symbolic link of the \"%s\" file failed", env->strerror(env, stack, errno, 0), path, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = placed_length;
  
  return 0;

#else

  return env->die(env, stack, "This method is not supported on this os(!defined(_WIN32))", __func__, FILE_NAME, __LINE__);

#endif

}

int32_t SPVM__Sys__IO__Windows__symlink(SPVM_ENV* env, SPVM_VALUE* stack) {
#if !defined(_WIN32)
  env->die(env, stack, "win32_symlink is not supported on this system(!defined(_WIN32))", __func__, FILE_NAME, __LINE__);
  return SPVM_NATIVE_C_CLASS_ID_ERROR_NOT_SUPPORTED;
#else
  int32_t e = 0;
  
  void* obj_oldpath = stack[0].oval;
  if (!obj_oldpath) {
    return env->die(env, stack, "The $oldpath must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* oldpath = env->get_chars(env, stack, obj_oldpath);

  void* obj_newpath = stack[1].oval;
  if (!obj_newpath) {
    return env->die(env, stack, "The $newpath must be defined", __func__, FILE_NAME, __LINE__);
  }
  const char* newpath = env->get_chars(env, stack, obj_newpath);
  
  errno = 0;
  int32_t status = win32_symlink(env, stack, oldpath, newpath);
  if (status == -1) {
    env->die(env, stack, "[System Error]win32_symlink failed:%s. The symbolic link from \"%s\" to \"%s\" can't be created", env->strerror(env, stack, errno, 0), oldpath, newpath, __func__, FILE_NAME, __LINE__);
    return SPVM_NATIVE_C_CLASS_ID_ERROR_SYSTEM;
  }
  
  stack[0].ival = status;
  
  return 0;
#endif
}

