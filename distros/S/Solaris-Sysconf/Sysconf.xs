#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/unistd.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant__XOPEN_XP(char *name, int len, int arg)
{
    if (9 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 1]) {
    case '3':
	if (strEQ(name + 9, "G3")) {	/* _XOPEN_XP removed */
#ifdef _XOPEN_XPG3
	    return _XOPEN_XPG3;
#else
	    goto not_there;
#endif
	}
    case '4':
	if (strEQ(name + 9, "G4")) {	/* _XOPEN_XP removed */
#ifdef _XOPEN_XPG4
	    return _XOPEN_XPG4;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__XOPEN_X(char *name, int len, int arg)
{
    switch (name[8 + 0]) {
    case 'C':
	if (strEQ(name + 8, "CU_VERSION")) {	/* _XOPEN_X removed */
#ifdef _XOPEN_XCU_VERSION
	    return _XOPEN_XCU_VERSION;
#else
	    goto not_there;
#endif
	}
    case 'P':
	return constant__XOPEN_XP(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__X(char *name, int len, int arg)
{
    if (2 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 5]) {
    case 'E':
	if (strEQ(name + 2, "OPEN_ENH_I18N")) {	/* _X removed */
#ifdef _XOPEN_ENH_I18N
	    return _XOPEN_ENH_I18N;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 2, "OPEN_REALTIME")) {	/* _X removed */
#ifdef _XOPEN_REALTIME
	    return _XOPEN_REALTIME;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 2, "OPEN_SHM")) {	/* _X removed */
#ifdef _XOPEN_SHM
	    return _XOPEN_SHM;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 2, "OPEN_UNIX")) {	/* _X removed */
#ifdef _XOPEN_UNIX
	    return _XOPEN_UNIX;
#else
	    goto not_there;
#endif
	}
    case 'X':
	if (!strnEQ(name + 2,"OPEN_", 5))
	    break;
	return constant__XOPEN_X(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__POSIX2_C_(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'B':
	if (strEQ(name + 10, "BIND")) {	/* _POSIX2_C_ removed */
#ifdef _POSIX2_C_BIND
	    return _POSIX2_C_BIND;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 10, "DEV")) {	/* _POSIX2_C_ removed */
#ifdef _POSIX2_C_DEV
	    return _POSIX2_C_DEV;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 10, "VERSION")) {	/* _POSIX2_C_ removed */
#ifdef _POSIX2_C_VERSION
	    return _POSIX2_C_VERSION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__POSIX2_C(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case 'H':
	if (strEQ(name + 9, "HAR_TERM")) {	/* _POSIX2_C removed */
#ifdef _POSIX2_CHAR_TERM
	    return _POSIX2_CHAR_TERM;
#else
	    goto not_there;
#endif
	}
    case '_':
	return constant__POSIX2_C_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__POSIX2(char *name, int len, int arg)
{
    if (7 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 1]) {
    case 'C':
	if (!strnEQ(name + 7,"_", 1))
	    break;
	return constant__POSIX2_C(name, len, arg);
    case 'L':
	if (strEQ(name + 7, "_LOCALEDEF")) {	/* _POSIX2 removed */
#ifdef _POSIX2_LOCALEDEF
	    return _POSIX2_LOCALEDEF;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 7, "_SW_DEV")) {	/* _POSIX2 removed */
#ifdef _POSIX2_SW_DEV
	    return _POSIX2_SW_DEV;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 7, "_UPE")) {	/* _POSIX2 removed */
#ifdef _POSIX2_UPE
	    return _POSIX2_UPE;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 7, "_VERSION")) {	/* _POSIX2 removed */
#ifdef _POSIX2_VERSION
	    return _POSIX2_VERSION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__PO(char *name, int len, int arg)
{
    if (3 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 3]) {
    case '2':
	if (!strnEQ(name + 3,"SIX", 3))
	    break;
	return constant__POSIX2(name, len, arg);
    case '_':
	if (strEQ(name + 3, "SIX_VERSION")) {	/* _PO removed */
#ifdef _POSIX_VERSION
	    return _POSIX_VERSION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__PC_N(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "AME_MAX")) {	/* _PC_N removed */
#ifdef _PC_NAME_MAX
	    return _PC_NAME_MAX;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 5, "O_TRUNC")) {	/* _PC_N removed */
#ifdef _PC_NO_TRUNC
	    return _PC_NO_TRUNC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__PC_P(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "ATH_MAX")) {	/* _PC_P removed */
#ifdef _PC_PATH_MAX
	    return _PC_PATH_MAX;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 5, "IPE_BUF")) {	/* _PC_P removed */
#ifdef _PC_PIPE_BUF
	    return _PC_PIPE_BUF;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 5, "RIO_IO")) {	/* _PC_P removed */
#ifdef _PC_PRIO_IO
	    return _PC_PRIO_IO;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__PC_L(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "AST")) {	/* _PC_L removed */
#ifdef _PC_LAST
	    return _PC_LAST;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 5, "INK_MAX")) {	/* _PC_L removed */
#ifdef _PC_LINK_MAX
	    return _PC_LINK_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__PC_M(char *name, int len, int arg)
{
    if (5 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 3]) {
    case 'C':
	if (strEQ(name + 5, "AX_CANON")) {	/* _PC_M removed */
#ifdef _PC_MAX_CANON
	    return _PC_MAX_CANON;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 5, "AX_INPUT")) {	/* _PC_M removed */
#ifdef _PC_MAX_INPUT
	    return _PC_MAX_INPUT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__PC(char *name, int len, int arg)
{
    if (3 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 1]) {
    case 'A':
	if (strEQ(name + 3, "_ASYNC_IO")) {	/* _PC removed */
#ifdef _PC_ASYNC_IO
	    return _PC_ASYNC_IO;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 3, "_CHOWN_RESTRICTED")) {	/* _PC removed */
#ifdef _PC_CHOWN_RESTRICTED
	    return _PC_CHOWN_RESTRICTED;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 3, "_FILESIZEBITS")) {	/* _PC removed */
#ifdef _PC_FILESIZEBITS
	    return _PC_FILESIZEBITS;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 3,"_", 1))
	    break;
	return constant__PC_L(name, len, arg);
    case 'M':
	if (!strnEQ(name + 3,"_", 1))
	    break;
	return constant__PC_M(name, len, arg);
    case 'N':
	if (!strnEQ(name + 3,"_", 1))
	    break;
	return constant__PC_N(name, len, arg);
    case 'P':
	if (!strnEQ(name + 3,"_", 1))
	    break;
	return constant__PC_P(name, len, arg);
    case 'S':
	if (strEQ(name + 3, "_SYNC_IO")) {	/* _PC removed */
#ifdef _PC_SYNC_IO
	    return _PC_SYNC_IO;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 3, "_VDISABLE")) {	/* _PC removed */
#ifdef _PC_VDISABLE
	    return _PC_VDISABLE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__P(char *name, int len, int arg)
{
    switch (name[2 + 0]) {
    case 'C':
	return constant__PC(name, len, arg);
    case 'O':
	return constant__PO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_AI(char *name, int len, int arg)
{
    if (6 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case 'L':
	if (strEQ(name + 6, "O_LISTIO_MAX")) {	/* _SC_AI removed */
#ifdef _SC_AIO_LISTIO_MAX
	    return _SC_AIO_LISTIO_MAX;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 6, "O_MAX")) {	/* _SC_AI removed */
#ifdef _SC_AIO_MAX
	    return _SC_AIO_MAX;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 6, "O_PRIO_DELTA_MAX")) {	/* _SC_AI removed */
#ifdef _SC_AIO_PRIO_DELTA_MAX
	    return _SC_AIO_PRIO_DELTA_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_A(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'I':
	return constant__SC_AI(name, len, arg);
    case 'R':
	if (strEQ(name + 5, "RG_MAX")) {	/* _SC_A removed */
#ifdef _SC_ARG_MAX
	    return _SC_ARG_MAX;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 5, "SYNCHRONOUS_IO")) {	/* _SC_A removed */
#ifdef _SC_ASYNCHRONOUS_IO
	    return _SC_ASYNCHRONOUS_IO;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 5, "TEXIT_MAX")) {	/* _SC_A removed */
#ifdef _SC_ATEXIT_MAX
	    return _SC_ATEXIT_MAX;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 5, "VPHYS_PAGES")) {	/* _SC_A removed */
#ifdef _SC_AVPHYS_PAGES
	    return _SC_AVPHYS_PAGES;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_BC_S(char *name, int len, int arg)
{
    switch (name[8 + 0]) {
    case 'C':
	if (strEQ(name + 8, "CALE_MAX")) {	/* _SC_BC_S removed */
#ifdef _SC_BC_SCALE_MAX
	    return _SC_BC_SCALE_MAX;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 8, "TRING_MAX")) {	/* _SC_BC_S removed */
#ifdef _SC_BC_STRING_MAX
	    return _SC_BC_STRING_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_B(char *name, int len, int arg)
{
    if (5 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 2]) {
    case 'B':
	if (strEQ(name + 5, "C_BASE_MAX")) {	/* _SC_B removed */
#ifdef _SC_BC_BASE_MAX
	    return _SC_BC_BASE_MAX;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 5, "C_DIM_MAX")) {	/* _SC_B removed */
#ifdef _SC_BC_DIM_MAX
	    return _SC_BC_DIM_MAX;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 5,"C_", 2))
	    break;
	return constant__SC_BC_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_CO(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'H':
	if (strEQ(name + 6, "HER_BLKSZ")) {	/* _SC_CO removed */
#ifdef _SC_COHER_BLKSZ
	    return _SC_COHER_BLKSZ;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 6, "LL_WEIGHTS_MAX")) {	/* _SC_CO removed */
#ifdef _SC_COLL_WEIGHTS_MAX
	    return _SC_COLL_WEIGHTS_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_C(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'H':
	if (strEQ(name + 5, "HILD_MAX")) {	/* _SC_C removed */
#ifdef _SC_CHILD_MAX
	    return _SC_CHILD_MAX;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 5, "LK_TCK")) {	/* _SC_C removed */
#ifdef _SC_CLK_TCK
	    return _SC_CLK_TCK;
#else
	    goto not_there;
#endif
	}
    case 'O':
	return constant__SC_CO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_DC(char *name, int len, int arg)
{
    if (6 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 5]) {
    case 'A':
	if (strEQ(name + 6, "ACHE_ASSOC")) {	/* _SC_DC removed */
#ifdef _SC_DCACHE_ASSOC
	    return _SC_DCACHE_ASSOC;
#else
	    goto not_there;
#endif
	}
    case 'B':
	if (strEQ(name + 6, "ACHE_BLKSZ")) {	/* _SC_DC removed */
#ifdef _SC_DCACHE_BLKSZ
	    return _SC_DCACHE_BLKSZ;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 6, "ACHE_LINESZ")) {	/* _SC_DC removed */
#ifdef _SC_DCACHE_LINESZ
	    return _SC_DCACHE_LINESZ;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "ACHE_SZ")) {	/* _SC_DC removed */
#ifdef _SC_DCACHE_SZ
	    return _SC_DCACHE_SZ;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 6, "ACHE_TBLKSZ")) {	/* _SC_DC removed */
#ifdef _SC_DCACHE_TBLKSZ
	    return _SC_DCACHE_TBLKSZ;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_D(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'C':
	return constant__SC_DC(name, len, arg);
    case 'E':
	if (strEQ(name + 5, "ELAYTIMER_MAX")) {	/* _SC_D removed */
#ifdef _SC_DELAYTIMER_MAX
	    return _SC_DELAYTIMER_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_G(char *name, int len, int arg)
{
    if (5 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 2]) {
    case 'G':
	if (strEQ(name + 5, "ETGR_R_SIZE_MAX")) {	/* _SC_G removed */
#ifdef _SC_GETGR_R_SIZE_MAX
	    return _SC_GETGR_R_SIZE_MAX;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 5, "ETPW_R_SIZE_MAX")) {	/* _SC_G removed */
#ifdef _SC_GETPW_R_SIZE_MAX
	    return _SC_GETPW_R_SIZE_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_IC(char *name, int len, int arg)
{
    if (6 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 5]) {
    case 'A':
	if (strEQ(name + 6, "ACHE_ASSOC")) {	/* _SC_IC removed */
#ifdef _SC_ICACHE_ASSOC
	    return _SC_ICACHE_ASSOC;
#else
	    goto not_there;
#endif
	}
    case 'B':
	if (strEQ(name + 6, "ACHE_BLKSZ")) {	/* _SC_IC removed */
#ifdef _SC_ICACHE_BLKSZ
	    return _SC_ICACHE_BLKSZ;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 6, "ACHE_LINESZ")) {	/* _SC_IC removed */
#ifdef _SC_ICACHE_LINESZ
	    return _SC_ICACHE_LINESZ;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "ACHE_SZ")) {	/* _SC_IC removed */
#ifdef _SC_ICACHE_SZ
	    return _SC_ICACHE_SZ;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_I(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'C':
	return constant__SC_IC(name, len, arg);
    case 'O':
	if (strEQ(name + 5, "OV_MAX")) {	/* _SC_I removed */
#ifdef _SC_IOV_MAX
	    return _SC_IOV_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_LO(char *name, int len, int arg)
{
    if (6 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'I':
	if (strEQ(name + 6, "GIN_NAME_MAX")) {	/* _SC_LO removed */
#ifdef _SC_LOGIN_NAME_MAX
	    return _SC_LOGIN_NAME_MAX;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 6, "GNAME_MAX")) {	/* _SC_LO removed */
#ifdef _SC_LOGNAME_MAX
	    return _SC_LOGNAME_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_L(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'I':
	if (strEQ(name + 5, "INE_MAX")) {	/* _SC_L removed */
#ifdef _SC_LINE_MAX
	    return _SC_LINE_MAX;
#else
	    goto not_there;
#endif
	}
    case 'O':
	return constant__SC_LO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_MQ(char *name, int len, int arg)
{
    if (6 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'O':
	if (strEQ(name + 6, "_OPEN_MAX")) {	/* _SC_MQ removed */
#ifdef _SC_MQ_OPEN_MAX
	    return _SC_MQ_OPEN_MAX;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 6, "_PRIO_MAX")) {	/* _SC_MQ removed */
#ifdef _SC_MQ_PRIO_MAX
	    return _SC_MQ_PRIO_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_MA(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'P':
	if (strEQ(name + 6, "PPED_FILES")) {	/* _SC_MA removed */
#ifdef _SC_MAPPED_FILES
	    return _SC_MAPPED_FILES;
#else
	    goto not_there;
#endif
	}
    case 'X':
	if (strEQ(name + 6, "XPID")) {	/* _SC_MA removed */
#ifdef _SC_MAXPID
	    return _SC_MAXPID;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_MEML(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case '\0':
	if (strEQ(name + 8, "OCK")) {	/* _SC_MEML removed */
#ifdef _SC_MEMLOCK
	    return _SC_MEMLOCK;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 8, "OCK_RANGE")) {	/* _SC_MEML removed */
#ifdef _SC_MEMLOCK_RANGE
	    return _SC_MEMLOCK_RANGE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_MEM(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'L':
	return constant__SC_MEML(name, len, arg);
    case 'O':
	if (strEQ(name + 7, "ORY_PROTECTION")) {	/* _SC_MEM removed */
#ifdef _SC_MEMORY_PROTECTION
	    return _SC_MEMORY_PROTECTION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_ME(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'M':
	return constant__SC_MEM(name, len, arg);
    case 'S':
	if (strEQ(name + 6, "SSAGE_PASSING")) {	/* _SC_ME removed */
#ifdef _SC_MESSAGE_PASSING
	    return _SC_MESSAGE_PASSING;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_M(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	return constant__SC_MA(name, len, arg);
    case 'E':
	return constant__SC_ME(name, len, arg);
    case 'Q':
	return constant__SC_MQ(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_NP(char *name, int len, int arg)
{
    if (6 + 10 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 10]) {
    case 'C':
	if (strEQ(name + 6, "ROCESSORS_CONF")) {	/* _SC_NP removed */
#ifdef _SC_NPROCESSORS_CONF
	    return _SC_NPROCESSORS_CONF;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 6, "ROCESSORS_ONLN")) {	/* _SC_NP removed */
#ifdef _SC_NPROCESSORS_ONLN
	    return _SC_NPROCESSORS_ONLN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_N(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'G':
	if (strEQ(name + 5, "GROUPS_MAX")) {	/* _SC_N removed */
#ifdef _SC_NGROUPS_MAX
	    return _SC_NGROUPS_MAX;
#else
	    goto not_there;
#endif
	}
    case 'P':
	return constant__SC_NP(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_PAG(char *name, int len, int arg)
{
    if (7 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 1]) {
    case 'S':
	if (strEQ(name + 7, "ESIZE")) {	/* _SC_PAG removed */
#ifdef _SC_PAGESIZE
	    return _SC_PAGESIZE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 7, "E_SIZE")) {	/* _SC_PAG removed */
#ifdef _SC_PAGE_SIZE
	    return _SC_PAGE_SIZE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_PA(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'G':
	return constant__SC_PAG(name, len, arg);
    case 'S':
	if (strEQ(name + 6, "SS_MAX")) {	/* _SC_PA removed */
#ifdef _SC_PASS_MAX
	    return _SC_PASS_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_PR(char *name, int len, int arg)
{
    if (6 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 5]) {
    case 'I':
	if (strEQ(name + 6, "IORITIZED_IO")) {	/* _SC_PR removed */
#ifdef _SC_PRIORITIZED_IO
	    return _SC_PRIORITIZED_IO;
#else
	    goto not_there;
#endif
	}
    case 'Y':
	if (strEQ(name + 6, "IORITY_SCHEDULING")) {	/* _SC_PR removed */
#ifdef _SC_PRIORITY_SCHEDULING
	    return _SC_PRIORITY_SCHEDULING;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_P(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	return constant__SC_PA(name, len, arg);
    case 'H':
	if (strEQ(name + 5, "HYS_PAGES")) {	/* _SC_P removed */
#ifdef _SC_PHYS_PAGES
	    return _SC_PHYS_PAGES;
#else
	    goto not_there;
#endif
	}
    case 'R':
	return constant__SC_PR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_2_F(char *name, int len, int arg)
{
    if (7 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 4]) {
    case 'D':
	if (strEQ(name + 7, "ORT_DEV")) {	/* _SC_2_F removed */
#ifdef _SC_2_FORT_DEV
	    return _SC_2_FORT_DEV;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 7, "ORT_RUN")) {	/* _SC_2_F removed */
#ifdef _SC_2_FORT_RUN
	    return _SC_2_FORT_RUN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_2_C_(char *name, int len, int arg)
{
    switch (name[8 + 0]) {
    case 'B':
	if (strEQ(name + 8, "BIND")) {	/* _SC_2_C_ removed */
#ifdef _SC_2_C_BIND
	    return _SC_2_C_BIND;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 8, "DEV")) {	/* _SC_2_C_ removed */
#ifdef _SC_2_C_DEV
	    return _SC_2_C_DEV;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 8, "VERSION")) {	/* _SC_2_C_ removed */
#ifdef _SC_2_C_VERSION
	    return _SC_2_C_VERSION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_2_C(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'H':
	if (strEQ(name + 7, "HAR_TERM")) {	/* _SC_2_C removed */
#ifdef _SC_2_CHAR_TERM
	    return _SC_2_CHAR_TERM;
#else
	    goto not_there;
#endif
	}
    case '_':
	return constant__SC_2_C_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_2(char *name, int len, int arg)
{
    if (5 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 1]) {
    case 'C':
	if (!strnEQ(name + 5,"_", 1))
	    break;
	return constant__SC_2_C(name, len, arg);
    case 'F':
	if (!strnEQ(name + 5,"_", 1))
	    break;
	return constant__SC_2_F(name, len, arg);
    case 'L':
	if (strEQ(name + 5, "_LOCALEDEF")) {	/* _SC_2 removed */
#ifdef _SC_2_LOCALEDEF
	    return _SC_2_LOCALEDEF;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 5, "_SW_DEV")) {	/* _SC_2 removed */
#ifdef _SC_2_SW_DEV
	    return _SC_2_SW_DEV;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 5, "_UPE")) {	/* _SC_2 removed */
#ifdef _SC_2_UPE
	    return _SC_2_UPE;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 5, "_VERSION")) {	/* _SC_2 removed */
#ifdef _SC_2_VERSION
	    return _SC_2_VERSION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_RE(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'A':
	if (strEQ(name + 6, "ALTIME_SIGNALS")) {	/* _SC_RE removed */
#ifdef _SC_REALTIME_SIGNALS
	    return _SC_REALTIME_SIGNALS;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 6, "_DUP_MAX")) {	/* _SC_RE removed */
#ifdef _SC_RE_DUP_MAX
	    return _SC_RE_DUP_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_R(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'E':
	return constant__SC_RE(name, len, arg);
    case 'T':
	if (strEQ(name + 5, "TSIG_MAX")) {	/* _SC_R removed */
#ifdef _SC_RTSIG_MAX
	    return _SC_RTSIG_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_SIGR(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case 'A':
	if (strEQ(name + 8, "T_MAX")) {	/* _SC_SIGR removed */
#ifdef _SC_SIGRT_MAX
	    return _SC_SIGRT_MAX;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 8, "T_MIN")) {	/* _SC_SIGR removed */
#ifdef _SC_SIGRT_MIN
	    return _SC_SIGRT_MIN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_SI(char *name, int len, int arg)
{
    if (6 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'Q':
	if (strEQ(name + 6, "GQUEUE_MAX")) {	/* _SC_SI removed */
#ifdef _SC_SIGQUEUE_MAX
	    return _SC_SIGQUEUE_MAX;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (!strnEQ(name + 6,"G", 1))
	    break;
	return constant__SC_SIGR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_ST(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'A':
	if (strEQ(name + 6, "ACK_PROT")) {	/* _SC_ST removed */
#ifdef _SC_STACK_PROT
	    return _SC_STACK_PROT;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 6, "REAM_MAX")) {	/* _SC_ST removed */
#ifdef _SC_STREAM_MAX
	    return _SC_STREAM_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_SEM_(char *name, int len, int arg)
{
    switch (name[8 + 0]) {
    case 'N':
	if (strEQ(name + 8, "NSEMS_MAX")) {	/* _SC_SEM_ removed */
#ifdef _SC_SEM_NSEMS_MAX
	    return _SC_SEM_NSEMS_MAX;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 8, "VALUE_MAX")) {	/* _SC_SEM_ removed */
#ifdef _SC_SEM_VALUE_MAX
	    return _SC_SEM_VALUE_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_SE(char *name, int len, int arg)
{
    if (6 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'A':
	if (strEQ(name + 6, "MAPHORES")) {	/* _SC_SE removed */
#ifdef _SC_SEMAPHORES
	    return _SC_SEMAPHORES;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 6,"M", 1))
	    break;
	return constant__SC_SEM_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_S(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "AVED_IDS")) {	/* _SC_S removed */
#ifdef _SC_SAVED_IDS
	    return _SC_SAVED_IDS;
#else
	    goto not_there;
#endif
	}
    case 'E':
	return constant__SC_SE(name, len, arg);
    case 'H':
	if (strEQ(name + 5, "HARED_MEMORY_OBJECTS")) {	/* _SC_S removed */
#ifdef _SC_SHARED_MEMORY_OBJECTS
	    return _SC_SHARED_MEMORY_OBJECTS;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant__SC_SI(name, len, arg);
    case 'P':
	if (strEQ(name + 5, "PLIT_CACHE")) {	/* _SC_S removed */
#ifdef _SC_SPLIT_CACHE
	    return _SC_SPLIT_CACHE;
#else
	    goto not_there;
#endif
	}
    case 'T':
	return constant__SC_ST(name, len, arg);
    case 'Y':
	if (strEQ(name + 5, "YNCHRONIZED_IO")) {	/* _SC_S removed */
#ifdef _SC_SYNCHRONIZED_IO
	    return _SC_SYNCHRONIZED_IO;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_THREAD_PRIO_(char *name, int len, int arg)
{
    switch (name[16 + 0]) {
    case 'I':
	if (strEQ(name + 16, "INHERIT")) {	/* _SC_THREAD_PRIO_ removed */
#ifdef _SC_THREAD_PRIO_INHERIT
	    return _SC_THREAD_PRIO_INHERIT;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 16, "PROTECT")) {	/* _SC_THREAD_PRIO_ removed */
#ifdef _SC_THREAD_PRIO_PROTECT
	    return _SC_THREAD_PRIO_PROTECT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_THREAD_PRI(char *name, int len, int arg)
{
    if (14 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[14 + 1]) {
    case 'R':
	if (strEQ(name + 14, "ORITY_SCHEDULING")) {	/* _SC_THREAD_PRI removed */
#ifdef _SC_THREAD_PRIORITY_SCHEDULING
	    return _SC_THREAD_PRIORITY_SCHEDULING;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 14,"O", 1))
	    break;
	return constant__SC_THREAD_PRIO_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_THREAD_P(char *name, int len, int arg)
{
    if (12 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case 'I':
	if (!strnEQ(name + 12,"R", 1))
	    break;
	return constant__SC_THREAD_PRI(name, len, arg);
    case 'O':
	if (strEQ(name + 12, "ROCESS_SHARED")) {	/* _SC_THREAD_P removed */
#ifdef _SC_THREAD_PROCESS_SHARED
	    return _SC_THREAD_PROCESS_SHARED;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_THREAD_A(char *name, int len, int arg)
{
    if (12 + 9 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 9]) {
    case 'A':
	if (strEQ(name + 12, "TTR_STACKADDR")) {	/* _SC_THREAD_A removed */
#ifdef _SC_THREAD_ATTR_STACKADDR
	    return _SC_THREAD_ATTR_STACKADDR;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 12, "TTR_STACKSIZE")) {	/* _SC_THREAD_A removed */
#ifdef _SC_THREAD_ATTR_STACKSIZE
	    return _SC_THREAD_ATTR_STACKSIZE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_THREAD_S(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case 'A':
	if (strEQ(name + 12, "AFE_FUNCTIONS")) {	/* _SC_THREAD_S removed */
#ifdef _SC_THREAD_SAFE_FUNCTIONS
	    return _SC_THREAD_SAFE_FUNCTIONS;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 12, "TACK_MIN")) {	/* _SC_THREAD_S removed */
#ifdef _SC_THREAD_STACK_MIN
	    return _SC_THREAD_STACK_MIN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_THREAD_(char *name, int len, int arg)
{
    switch (name[11 + 0]) {
    case 'A':
	return constant__SC_THREAD_A(name, len, arg);
    case 'D':
	if (strEQ(name + 11, "DESTRUCTOR_ITERATIONS")) {	/* _SC_THREAD_ removed */
#ifdef _SC_THREAD_DESTRUCTOR_ITERATIONS
	    return _SC_THREAD_DESTRUCTOR_ITERATIONS;
#else
	    goto not_there;
#endif
	}
    case 'K':
	if (strEQ(name + 11, "KEYS_MAX")) {	/* _SC_THREAD_ removed */
#ifdef _SC_THREAD_KEYS_MAX
	    return _SC_THREAD_KEYS_MAX;
#else
	    goto not_there;
#endif
	}
    case 'P':
	return constant__SC_THREAD_P(name, len, arg);
    case 'S':
	return constant__SC_THREAD_S(name, len, arg);
    case 'T':
	if (strEQ(name + 11, "THREADS_MAX")) {	/* _SC_THREAD_ removed */
#ifdef _SC_THREAD_THREADS_MAX
	    return _SC_THREAD_THREADS_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_TH(char *name, int len, int arg)
{
    if (6 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 4]) {
    case 'S':
	if (strEQ(name + 6, "READS")) {	/* _SC_TH removed */
#ifdef _SC_THREADS
	    return _SC_THREADS;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 6,"READ", 4))
	    break;
	return constant__SC_THREAD_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_TI(char *name, int len, int arg)
{
    if (6 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case 'S':
	if (strEQ(name + 6, "MERS")) {	/* _SC_TI removed */
#ifdef _SC_TIMERS
	    return _SC_TIMERS;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 6, "MER_MAX")) {	/* _SC_TI removed */
#ifdef _SC_TIMER_MAX
	    return _SC_TIMER_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_T(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'H':
	return constant__SC_TH(name, len, arg);
    case 'I':
	return constant__SC_TI(name, len, arg);
    case 'T':
	if (strEQ(name + 5, "TY_NAME_MAX")) {	/* _SC_T removed */
#ifdef _SC_TTY_NAME_MAX
	    return _SC_TTY_NAME_MAX;
#else
	    goto not_there;
#endif
	}
    case 'Z':
	if (strEQ(name + 5, "ZNAME_MAX")) {	/* _SC_T removed */
#ifdef _SC_TZNAME_MAX
	    return _SC_TZNAME_MAX;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 5, "_IOV_MAX")) {	/* _SC_T removed */
#ifdef _SC_T_IOV_MAX
	    return _SC_T_IOV_MAX;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_XOPEN_R(char *name, int len, int arg)
{
    if (11 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 7]) {
    case '\0':
	if (strEQ(name + 11, "EALTIME")) {	/* _SC_XOPEN_R removed */
#ifdef _SC_XOPEN_REALTIME
	    return _SC_XOPEN_REALTIME;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 11, "EALTIME_THREADS")) {	/* _SC_XOPEN_R removed */
#ifdef _SC_XOPEN_REALTIME_THREADS
	    return _SC_XOPEN_REALTIME_THREADS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_XO(char *name, int len, int arg)
{
    if (6 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 4]) {
    case 'C':
	if (strEQ(name + 6, "PEN_CRYPT")) {	/* _SC_XO removed */
#ifdef _SC_XOPEN_CRYPT
	    return _SC_XOPEN_CRYPT;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 6, "PEN_ENH_I18N")) {	/* _SC_XO removed */
#ifdef _SC_XOPEN_ENH_I18N
	    return _SC_XOPEN_ENH_I18N;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 6, "PEN_LEGACY")) {	/* _SC_XO removed */
#ifdef _SC_XOPEN_LEGACY
	    return _SC_XOPEN_LEGACY;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (!strnEQ(name + 6,"PEN_", 4))
	    break;
	return constant__SC_XOPEN_R(name, len, arg);
    case 'S':
	if (strEQ(name + 6, "PEN_SHM")) {	/* _SC_XO removed */
#ifdef _SC_XOPEN_SHM
	    return _SC_XOPEN_SHM;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 6, "PEN_UNIX")) {	/* _SC_XO removed */
#ifdef _SC_XOPEN_UNIX
	    return _SC_XOPEN_UNIX;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 6, "PEN_VERSION")) {	/* _SC_XO removed */
#ifdef _SC_XOPEN_VERSION
	    return _SC_XOPEN_VERSION;
#else
	    goto not_there;
#endif
	}
    case 'X':
	if (strEQ(name + 6, "PEN_XCU_VERSION")) {	/* _SC_XO removed */
#ifdef _SC_XOPEN_XCU_VERSION
	    return _SC_XOPEN_XCU_VERSION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_XBS5_I(char *name, int len, int arg)
{
    if (10 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 8]) {
    case '3':
	if (strEQ(name + 10, "LP32_OFF32")) {	/* _SC_XBS5_I removed */
#ifdef _SC_XBS5_ILP32_OFF32
	    return _SC_XBS5_ILP32_OFF32;
#else
	    goto not_there;
#endif
	}
    case 'B':
	if (strEQ(name + 10, "LP32_OFFBIG")) {	/* _SC_XBS5_I removed */
#ifdef _SC_XBS5_ILP32_OFFBIG
	    return _SC_XBS5_ILP32_OFFBIG;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_XBS5_L(char *name, int len, int arg)
{
    if (10 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 1]) {
    case '6':
	if (strEQ(name + 10, "P64_OFF64")) {	/* _SC_XBS5_L removed */
#ifdef _SC_XBS5_LP64_OFF64
	    return _SC_XBS5_LP64_OFF64;
#else
	    goto not_there;
#endif
	}
    case 'B':
	if (strEQ(name + 10, "PBIG_OFFBIG")) {	/* _SC_XBS5_L removed */
#ifdef _SC_XBS5_LPBIG_OFFBIG
	    return _SC_XBS5_LPBIG_OFFBIG;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_XB(char *name, int len, int arg)
{
    if (6 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case 'I':
	if (!strnEQ(name + 6,"S5_", 3))
	    break;
	return constant__SC_XBS5_I(name, len, arg);
    case 'L':
	if (!strnEQ(name + 6,"S5_", 3))
	    break;
	return constant__SC_XBS5_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__SC_X(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'B':
	return constant__SC_XB(name, len, arg);
    case 'O':
	return constant__SC_XO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__S(char *name, int len, int arg)
{
    if (2 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 2]) {
    case '2':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_2(name, len, arg);
    case 'A':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_A(name, len, arg);
    case 'B':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_B(name, len, arg);
    case 'C':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_C(name, len, arg);
    case 'D':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_D(name, len, arg);
    case 'E':
	if (strEQ(name + 2, "C_EXPR_NEST_MAX")) {	/* _S removed */
#ifdef _SC_EXPR_NEST_MAX
	    return _SC_EXPR_NEST_MAX;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 2, "C_FSYNC")) {	/* _S removed */
#ifdef _SC_FSYNC
	    return _SC_FSYNC;
#else
	    goto not_there;
#endif
	}
    case 'G':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_G(name, len, arg);
    case 'I':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_I(name, len, arg);
    case 'J':
	if (strEQ(name + 2, "C_JOB_CONTROL")) {	/* _S removed */
#ifdef _SC_JOB_CONTROL
	    return _SC_JOB_CONTROL;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_L(name, len, arg);
    case 'M':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_M(name, len, arg);
    case 'N':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_N(name, len, arg);
    case 'O':
	if (strEQ(name + 2, "C_OPEN_MAX")) {	/* _S removed */
#ifdef _SC_OPEN_MAX
	    return _SC_OPEN_MAX;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_P(name, len, arg);
    case 'R':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_R(name, len, arg);
    case 'S':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_S(name, len, arg);
    case 'T':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_T(name, len, arg);
    case 'V':
	if (strEQ(name + 2, "C_VERSION")) {	/* _S removed */
#ifdef _SC_VERSION
	    return _SC_VERSION;
#else
	    goto not_there;
#endif
	}
    case 'X':
	if (!strnEQ(name + 2,"C_", 2))
	    break;
	return constant__SC_X(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_LFS_LI(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'B':
	if (strEQ(name + 10, "BS")) {	/* _CS_LFS_LI removed */
#ifdef _CS_LFS_LIBS
	    return _CS_LFS_LIBS;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 10, "NTFLAGS")) {	/* _CS_LFS_LI removed */
#ifdef _CS_LFS_LINTFLAGS
	    return _CS_LFS_LINTFLAGS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_LFS_L(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case 'D':
	if (strEQ(name + 9, "DFLAGS")) {	/* _CS_LFS_L removed */
#ifdef _CS_LFS_LDFLAGS
	    return _CS_LFS_LDFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant__CS_LFS_LI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_LFS_(char *name, int len, int arg)
{
    switch (name[8 + 0]) {
    case 'C':
	if (strEQ(name + 8, "CFLAGS")) {	/* _CS_LFS_ removed */
#ifdef _CS_LFS_CFLAGS
	    return _CS_LFS_CFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'L':
	return constant__CS_LFS_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_LFS64_LI(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case 'B':
	if (strEQ(name + 12, "BS")) {	/* _CS_LFS64_LI removed */
#ifdef _CS_LFS64_LIBS
	    return _CS_LFS64_LIBS;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 12, "NTFLAGS")) {	/* _CS_LFS64_LI removed */
#ifdef _CS_LFS64_LINTFLAGS
	    return _CS_LFS64_LINTFLAGS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_LFS64_L(char *name, int len, int arg)
{
    switch (name[11 + 0]) {
    case 'D':
	if (strEQ(name + 11, "DFLAGS")) {	/* _CS_LFS64_L removed */
#ifdef _CS_LFS64_LDFLAGS
	    return _CS_LFS64_LDFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant__CS_LFS64_LI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_LFS6(char *name, int len, int arg)
{
    if (8 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 2]) {
    case 'C':
	if (strEQ(name + 8, "4_CFLAGS")) {	/* _CS_LFS6 removed */
#ifdef _CS_LFS64_CFLAGS
	    return _CS_LFS64_CFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 8,"4_", 2))
	    break;
	return constant__CS_LFS64_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_L(char *name, int len, int arg)
{
    if (5 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 2]) {
    case '6':
	if (!strnEQ(name + 5,"FS", 2))
	    break;
	return constant__CS_LFS6(name, len, arg);
    case '_':
	if (!strnEQ(name + 5,"FS", 2))
	    break;
	return constant__CS_LFS_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_ILP32_OFFBIG_LI(char *name, int len, int arg)
{
    switch (name[24 + 0]) {
    case 'B':
	if (strEQ(name + 24, "BS")) {	/* _CS_XBS5_ILP32_OFFBIG_LI removed */
#ifdef _CS_XBS5_ILP32_OFFBIG_LIBS
	    return _CS_XBS5_ILP32_OFFBIG_LIBS;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 24, "NTFLAGS")) {	/* _CS_XBS5_ILP32_OFFBIG_LI removed */
#ifdef _CS_XBS5_ILP32_OFFBIG_LINTFLAGS
	    return _CS_XBS5_ILP32_OFFBIG_LINTFLAGS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_ILP32_OFFBIG_L(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'D':
	if (strEQ(name + 23, "DFLAGS")) {	/* _CS_XBS5_ILP32_OFFBIG_L removed */
#ifdef _CS_XBS5_ILP32_OFFBIG_LDFLAGS
	    return _CS_XBS5_ILP32_OFFBIG_LDFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant__CS_XBS5_ILP32_OFFBIG_LI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_ILP32_OFFB(char *name, int len, int arg)
{
    if (19 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 3]) {
    case 'C':
	if (strEQ(name + 19, "IG_CFLAGS")) {	/* _CS_XBS5_ILP32_OFFB removed */
#ifdef _CS_XBS5_ILP32_OFFBIG_CFLAGS
	    return _CS_XBS5_ILP32_OFFBIG_CFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 19,"IG_", 3))
	    break;
	return constant__CS_XBS5_ILP32_OFFBIG_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_ILP32_OFF32_LI(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'B':
	if (strEQ(name + 23, "BS")) {	/* _CS_XBS5_ILP32_OFF32_LI removed */
#ifdef _CS_XBS5_ILP32_OFF32_LIBS
	    return _CS_XBS5_ILP32_OFF32_LIBS;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 23, "NTFLAGS")) {	/* _CS_XBS5_ILP32_OFF32_LI removed */
#ifdef _CS_XBS5_ILP32_OFF32_LINTFLAGS
	    return _CS_XBS5_ILP32_OFF32_LINTFLAGS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_ILP32_OFF32_L(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'D':
	if (strEQ(name + 22, "DFLAGS")) {	/* _CS_XBS5_ILP32_OFF32_L removed */
#ifdef _CS_XBS5_ILP32_OFF32_LDFLAGS
	    return _CS_XBS5_ILP32_OFF32_LDFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant__CS_XBS5_ILP32_OFF32_LI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_ILP32_OFF3(char *name, int len, int arg)
{
    if (19 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 2]) {
    case 'C':
	if (strEQ(name + 19, "2_CFLAGS")) {	/* _CS_XBS5_ILP32_OFF3 removed */
#ifdef _CS_XBS5_ILP32_OFF32_CFLAGS
	    return _CS_XBS5_ILP32_OFF32_CFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 19,"2_", 2))
	    break;
	return constant__CS_XBS5_ILP32_OFF32_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_I(char *name, int len, int arg)
{
    if (10 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 8]) {
    case '3':
	if (!strnEQ(name + 10,"LP32_OFF", 8))
	    break;
	return constant__CS_XBS5_ILP32_OFF3(name, len, arg);
    case 'B':
	if (!strnEQ(name + 10,"LP32_OFF", 8))
	    break;
	return constant__CS_XBS5_ILP32_OFFB(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_LPBIG_OFFBIG_LI(char *name, int len, int arg)
{
    switch (name[24 + 0]) {
    case 'B':
	if (strEQ(name + 24, "BS")) {	/* _CS_XBS5_LPBIG_OFFBIG_LI removed */
#ifdef _CS_XBS5_LPBIG_OFFBIG_LIBS
	    return _CS_XBS5_LPBIG_OFFBIG_LIBS;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 24, "NTFLAGS")) {	/* _CS_XBS5_LPBIG_OFFBIG_LI removed */
#ifdef _CS_XBS5_LPBIG_OFFBIG_LINTFLAGS
	    return _CS_XBS5_LPBIG_OFFBIG_LINTFLAGS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_LPBIG_OFFBIG_L(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'D':
	if (strEQ(name + 23, "DFLAGS")) {	/* _CS_XBS5_LPBIG_OFFBIG_L removed */
#ifdef _CS_XBS5_LPBIG_OFFBIG_LDFLAGS
	    return _CS_XBS5_LPBIG_OFFBIG_LDFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant__CS_XBS5_LPBIG_OFFBIG_LI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_LPB(char *name, int len, int arg)
{
    if (12 + 10 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 10]) {
    case 'C':
	if (strEQ(name + 12, "IG_OFFBIG_CFLAGS")) {	/* _CS_XBS5_LPB removed */
#ifdef _CS_XBS5_LPBIG_OFFBIG_CFLAGS
	    return _CS_XBS5_LPBIG_OFFBIG_CFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 12,"IG_OFFBIG_", 10))
	    break;
	return constant__CS_XBS5_LPBIG_OFFBIG_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_LP64_OFF64_LI(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'B':
	if (strEQ(name + 22, "BS")) {	/* _CS_XBS5_LP64_OFF64_LI removed */
#ifdef _CS_XBS5_LP64_OFF64_LIBS
	    return _CS_XBS5_LP64_OFF64_LIBS;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 22, "NTFLAGS")) {	/* _CS_XBS5_LP64_OFF64_LI removed */
#ifdef _CS_XBS5_LP64_OFF64_LINTFLAGS
	    return _CS_XBS5_LP64_OFF64_LINTFLAGS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_LP64_OFF64_L(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'D':
	if (strEQ(name + 21, "DFLAGS")) {	/* _CS_XBS5_LP64_OFF64_L removed */
#ifdef _CS_XBS5_LP64_OFF64_LDFLAGS
	    return _CS_XBS5_LP64_OFF64_LDFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant__CS_XBS5_LP64_OFF64_LI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_LP6(char *name, int len, int arg)
{
    if (12 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 8]) {
    case 'C':
	if (strEQ(name + 12, "4_OFF64_CFLAGS")) {	/* _CS_XBS5_LP6 removed */
#ifdef _CS_XBS5_LP64_OFF64_CFLAGS
	    return _CS_XBS5_LP64_OFF64_CFLAGS;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 12,"4_OFF64_", 8))
	    break;
	return constant__CS_XBS5_LP64_OFF64_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_XBS5_L(char *name, int len, int arg)
{
    if (10 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 1]) {
    case '6':
	if (!strnEQ(name + 10,"P", 1))
	    break;
	return constant__CS_XBS5_LP6(name, len, arg);
    case 'B':
	if (!strnEQ(name + 10,"P", 1))
	    break;
	return constant__CS_XBS5_LPB(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__CS_X(char *name, int len, int arg)
{
    if (5 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 4]) {
    case 'I':
	if (!strnEQ(name + 5,"BS5_", 4))
	    break;
	return constant__CS_XBS5_I(name, len, arg);
    case 'L':
	if (!strnEQ(name + 5,"BS5_", 4))
	    break;
	return constant__CS_XBS5_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant__C(char *name, int len, int arg)
{
    if (2 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 2]) {
    case 'L':
	if (!strnEQ(name + 2,"S_", 2))
	    break;
	return constant__CS_L(name, len, arg);
    case 'P':
	if (strEQ(name + 2, "S_PATH")) {	/* _C removed */
#ifdef _CS_PATH
	    return _CS_PATH;
#else
	    goto not_there;
#endif
	}
    case 'X':
	if (!strnEQ(name + 2,"S_", 2))
	    break;
	return constant__CS_X(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 1]) {
    case 'C':
	if (!strnEQ(name + 0,"_", 1))
	    break;
	return constant__C(name, len, arg);
    case 'P':
	if (!strnEQ(name + 0,"_", 1))
	    break;
	return constant__P(name, len, arg);
    case 'S':
	if (!strnEQ(name + 0,"_", 1))
	    break;
	return constant__S(name, len, arg);
    case 'X':
	if (!strnEQ(name + 0,"_", 1))
	    break;
	return constant__X(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Solaris::Sysconf		PACKAGE = Solaris::Sysconf		
PROTOTYPES: DISABLE

long
sysconf(name)
   int name
CODE:
   RETVAL = sysconf(name);
OUTPUT:
   RETVAL

double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

