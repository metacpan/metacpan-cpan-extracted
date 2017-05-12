/*
#
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ctapi.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_OP_N(char *name, int len, int arg)
{
    if (4 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 1]) {
    case '\0':
	if (strEQ(name + 4, "E")) {	/* OP_N removed */
#ifdef OP_NE
	    return OP_NE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 4, "E_CS")) {	/* OP_N removed */
#ifdef OP_NE_CS
	    return OP_NE_CS;
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
constant_OP_G(char *name, int len, int arg)
{
    switch (name[4 + 0]) {
    case 'E':
	if (strEQ(name + 4, "E")) {	/* OP_G removed */
#ifdef OP_GE
	    return OP_GE;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 4, "T")) {	/* OP_G removed */
#ifdef OP_GT
	    return OP_GT;
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
constant_OP_S(char *name, int len, int arg)
{
    if (4 + 9 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 9]) {
    case '\0':
	if (strEQ(name + 4, "TARTSWITH")) {	/* OP_S removed */
#ifdef OP_STARTSWITH
	    return OP_STARTSWITH;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 4, "TARTSWITH_CS")) {	/* OP_S removed */
#ifdef OP_STARTSWITH_CS
	    return OP_STARTSWITH_CS;
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
constant_OP_L(char *name, int len, int arg)
{
    switch (name[4 + 0]) {
    case 'E':
	if (strEQ(name + 4, "E")) {	/* OP_L removed */
#ifdef OP_LE
	    return OP_LE;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 4, "T")) {	/* OP_L removed */
#ifdef OP_LT
	    return OP_LT;
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
constant_OP_E(char *name, int len, int arg)
{
    if (4 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 1]) {
    case '\0':
	if (strEQ(name + 4, "Q")) {	/* OP_E removed */
#ifdef OP_EQ
	    return OP_EQ;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 4, "Q_CS")) {	/* OP_E removed */
#ifdef OP_EQ_CS
	    return OP_EQ_CS;
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
constant_O(char *name, int len, int arg)
{
    if (1 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 2]) {
    case 'E':
	if (!strnEQ(name + 1,"P_", 2))
	    break;
	return constant_OP_E(name, len, arg);
    case 'G':
	if (!strnEQ(name + 1,"P_", 2))
	    break;
	return constant_OP_G(name, len, arg);
    case 'L':
	if (!strnEQ(name + 1,"P_", 2))
	    break;
	return constant_OP_L(name, len, arg);
    case 'N':
	if (!strnEQ(name + 1,"P_", 2))
	    break;
	return constant_OP_N(name, len, arg);
    case 'S':
	if (!strnEQ(name + 1,"P_", 2))
	    break;
	return constant_OP_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_S(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'E':
	if (strEQ(name + 1, "ESSION_INITIALIZER")) {	/* S removed */
#ifdef SESSION_INITIALIZER
	    return SESSION_INITIALIZER;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 1, "TREAM_INITIALIZER")) {	/* S removed */
#ifdef STREAM_INITIALIZER
	    return STREAM_INITIALIZER;
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
constant_CAPI_N(char *name, int len, int arg)
{
    if (6 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 6]) {
    case 'E':
	if (strEQ(name + 6, "OTIFY_EMAIL")) {	/* CAPI_N removed */
#ifdef CAPI_NOTIFY_EMAIL
	    return CAPI_NOTIFY_EMAIL;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "OTIFY_SMS")) {	/* CAPI_N removed */
#ifdef CAPI_NOTIFY_SMS
	    return CAPI_NOTIFY_SMS;
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
constant_CAPI_FLAG_FETCH_EXCLUDE_D(char *name, int len, int arg)
{
    if (25 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[25 + 1]) {
    case 'I':
	if (strEQ(name + 25, "AILYNOTES")) {	/* CAPI_FLAG_FETCH_EXCLUDE_D removed */
#ifdef CAPI_FLAG_FETCH_EXCLUDE_DAILYNOTES
	    return CAPI_FLAG_FETCH_EXCLUDE_DAILYNOTES;
#else
	    goto not_there;
#endif
	}
    case 'Y':
	if (strEQ(name + 25, "AYEVENTS")) {	/* CAPI_FLAG_FETCH_EXCLUDE_D removed */
#ifdef CAPI_FLAG_FETCH_EXCLUDE_DAYEVENTS
	    return CAPI_FLAG_FETCH_EXCLUDE_DAYEVENTS;
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
constant_CAPI_FLAG_FETCH_E(char *name, int len, int arg)
{
    if (17 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 7]) {
    case 'A':
	if (strEQ(name + 17, "XCLUDE_APPOINTMENTS")) {	/* CAPI_FLAG_FETCH_E removed */
#ifdef CAPI_FLAG_FETCH_EXCLUDE_APPOINTMENTS
	    return CAPI_FLAG_FETCH_EXCLUDE_APPOINTMENTS;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (!strnEQ(name + 17,"XCLUDE_", 7))
	    break;
	return constant_CAPI_FLAG_FETCH_EXCLUDE_D(name, len, arg);
    case 'H':
	if (strEQ(name + 17, "XCLUDE_HOLIDAYS")) {	/* CAPI_FLAG_FETCH_E removed */
#ifdef CAPI_FLAG_FETCH_EXCLUDE_HOLIDAYS
	    return CAPI_FLAG_FETCH_EXCLUDE_HOLIDAYS;
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
constant_CAPI_FLAG_F(char *name, int len, int arg)
{
    if (11 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 5]) {
    case 'E':
	if (!strnEQ(name + 11,"ETCH_", 5))
	    break;
	return constant_CAPI_FLAG_FETCH_E(name, len, arg);
    case 'N':
	if (strEQ(name + 11, "ETCH_NO_FIELDHOLDERS")) {	/* CAPI_FLAG_F removed */
#ifdef CAPI_FLAG_FETCH_NO_FIELDHOLDERS
	    return CAPI_FLAG_FETCH_NO_FIELDHOLDERS;
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
constant_CAPI_FLAG_A(char *name, int len, int arg)
{
    if (11 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 5]) {
    case 'D':
	if (strEQ(name + 11, "LARM_DUETIME")) {	/* CAPI_FLAG_A removed */
#ifdef CAPI_FLAG_ALARM_DUETIME
	    return CAPI_FLAG_ALARM_DUETIME;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 11, "LARM_STARTTIME")) {	/* CAPI_FLAG_A removed */
#ifdef CAPI_FLAG_ALARM_STARTTIME
	    return CAPI_FLAG_ALARM_STARTTIME;
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
constant_CAPI_FLAG_S(char *name, int len, int arg)
{
    if (11 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 5]) {
    case 'D':
	if (strEQ(name + 11, "TORE_DELPROPS")) {	/* CAPI_FLAG_S removed */
#ifdef CAPI_FLAG_STORE_DELPROPS
	    return CAPI_FLAG_STORE_DELPROPS;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 11, "TORE_MODPROPS")) {	/* CAPI_FLAG_S removed */
#ifdef CAPI_FLAG_STORE_MODPROPS
	    return CAPI_FLAG_STORE_MODPROPS;
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
constant_CAPI_FLAG_(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'A':
	return constant_CAPI_FLAG_A(name, len, arg);
    case 'F':
	return constant_CAPI_FLAG_F(name, len, arg);
    case 'N':
	if (strEQ(name + 10, "NONE")) {	/* CAPI_FLAG_ removed */
#ifdef CAPI_FLAG_NONE
	    return CAPI_FLAG_NONE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	return constant_CAPI_FLAG_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_F(char *name, int len, int arg)
{
    if (6 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case 'S':
	if (strEQ(name + 6, "LAGS_NONE")) {	/* CAPI_F removed */
#ifdef CAPI_FLAGS_NONE
	    return CAPI_FLAGS_NONE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 6,"LAG", 3))
	    break;
	return constant_CAPI_FLAG_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_GetS(char *name, int len, int arg)
{
    if (9 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 5]) {
    case 'L':
	if (strEQ(name + 9, "tatusLevels")) {	/* CAPI_GetS removed */
#ifdef CAPI_GetStatusLevels
	    return (IV)CAPI_GetStatusLevels;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 9, "tatusString")) {	/* CAPI_GetS removed */
#ifdef CAPI_GetStatusString
	    return (IV)CAPI_GetStatusString;
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
constant_CAPI_G(char *name, int len, int arg)
{
    if (6 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case 'C':
	if (strEQ(name + 6, "etCapabilities")) {	/* CAPI_G removed */
#ifdef CAPI_GetCapabilities
	    return (IV)CAPI_GetCapabilities;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 6, "etHandle")) {	/* CAPI_G removed */
#ifdef CAPI_GetHandle
	    return (IV)CAPI_GetHandle;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 6,"et", 2))
	    break;
	return constant_CAPI_GetS(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_HA(char *name, int len, int arg)
{
    if (7 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 5]) {
    case 'I':
	if (strEQ(name + 7, "NDLE_INITIALIZER")) {	/* CAPI_HA removed */
#ifdef CAPI_HANDLE_INITIALIZER
	    return CAPI_HANDLE_INITIALIZER;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 7, "NDLE_MAILTO")) {	/* CAPI_HA removed */
#ifdef CAPI_HANDLE_MAILTO
	    return CAPI_HANDLE_MAILTO;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 7, "NDLE_NAME")) {	/* CAPI_HA removed */
#ifdef CAPI_HANDLE_NAME
	    return CAPI_HANDLE_NAME;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 7, "NDLE_TYPE")) {	/* CAPI_HA removed */
#ifdef CAPI_HANDLE_TYPE
	    return CAPI_HANDLE_TYPE;
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
constant_CAPI_H(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case '\0':
	if (strEQ(name + 6, "")) {	/* CAPI_H removed */
#ifdef CAPI_H
	    return CAPI_H;
#else
	    goto not_there;
#endif
	}
    case 'A':
	return constant_CAPI_HA(name, len, arg);
    case 'a':
	if (strEQ(name + 6, "andleInfo")) {	/* CAPI_H removed */
#ifdef CAPI_HandleInfo
	    return (IV)CAPI_HandleInfo;
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
constant_CAPI_A(char *name, int len, int arg)
{
    if (6 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 5]) {
    case 'D':
	if (strEQ(name + 6, "LARM_DUETIME")) {	/* CAPI_A removed */
#ifdef CAPI_ALARM_DUETIME
	    return CAPI_ALARM_DUETIME;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "LARM_STARTTIME")) {	/* CAPI_A removed */
#ifdef CAPI_ALARM_STARTTIME
	    return CAPI_ALARM_STARTTIME;
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
constant_CAPI_Se(char *name, int len, int arg)
{
    if (7 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 1]) {
    case 'C':
	if (strEQ(name + 7, "tConfigFile")) {	/* CAPI_Se removed */
#ifdef CAPI_SetConfigFile
	    return (IV)CAPI_SetConfigFile;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 7, "tIdentity")) {	/* CAPI_Se removed */
#ifdef CAPI_SetIdentity
	    return (IV)CAPI_SetIdentity;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 7, "tStreamCallbacks")) {	/* CAPI_Se removed */
#ifdef CAPI_SetStreamCallbacks
	    return (IV)CAPI_SetStreamCallbacks;
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
constant_CAPI_STO(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case 'D':
	if (strEQ(name + 8, "RE_DELPROP")) {	/* CAPI_STO removed */
#ifdef CAPI_STORE_DELPROP
	    return CAPI_STORE_DELPROP;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 8, "RE_REPLACE")) {	/* CAPI_STO removed */
#ifdef CAPI_STORE_REPLACE
	    return CAPI_STORE_REPLACE;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 8, "RE_UPDATE")) {	/* CAPI_STO removed */
#ifdef CAPI_STORE_UPDATE
	    return CAPI_STORE_UPDATE;
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
constant_CAPI_STAT_API_POOL_N(char *name, int len, int arg)
{
    if (20 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 1]) {
    case 'C':
	if (strEQ(name + 20, "OCONNECTIONS")) {	/* CAPI_STAT_API_POOL_N removed */
#ifdef CAPI_STAT_API_POOL_NOCONNECTIONS
	    return CAPI_STAT_API_POOL_NOCONNECTIONS;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 20, "OTINITIALIZED")) {	/* CAPI_STAT_API_POOL_N removed */
#ifdef CAPI_STAT_API_POOL_NOTINITIALIZED
	    return CAPI_STAT_API_POOL_NOTINITIALIZED;
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
constant_CAPI_STAT_API_POOL_(char *name, int len, int arg)
{
    switch (name[19 + 0]) {
    case 'L':
	if (strEQ(name + 19, "LOCKFAILED")) {	/* CAPI_STAT_API_POOL_ removed */
#ifdef CAPI_STAT_API_POOL_LOCKFAILED
	    return CAPI_STAT_API_POOL_LOCKFAILED;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_CAPI_STAT_API_POOL_N(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_P(char *name, int len, int arg)
{
    if (15 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 3]) {
    case '\0':
	if (strEQ(name + 15, "OOL")) {	/* CAPI_STAT_API_P removed */
#ifdef CAPI_STAT_API_POOL
	    return CAPI_STAT_API_POOL;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 15,"OOL", 3))
	    break;
	return constant_CAPI_STAT_API_POOL_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_HANDLE_N(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'O':
	if (strEQ(name + 22, "OTNULL")) {	/* CAPI_STAT_API_HANDLE_N removed */
#ifdef CAPI_STAT_API_HANDLE_NOTNULL
	    return CAPI_STAT_API_HANDLE_NOTNULL;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 22, "ULL")) {	/* CAPI_STAT_API_HANDLE_N removed */
#ifdef CAPI_STAT_API_HANDLE_NULL
	    return CAPI_STAT_API_HANDLE_NULL;
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
constant_CAPI_STAT_API_HANDLE_(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'B':
	if (strEQ(name + 21, "BAD")) {	/* CAPI_STAT_API_HANDLE_ removed */
#ifdef CAPI_STAT_API_HANDLE_BAD
	    return CAPI_STAT_API_HANDLE_BAD;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_CAPI_STAT_API_HANDLE_N(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_H(char *name, int len, int arg)
{
    if (15 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 5]) {
    case '\0':
	if (strEQ(name + 15, "ANDLE")) {	/* CAPI_STAT_API_H removed */
#ifdef CAPI_STAT_API_HANDLE
	    return CAPI_STAT_API_HANDLE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 15,"ANDLE", 5))
	    break;
	return constant_CAPI_STAT_API_HANDLE_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_STREAM_N(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'O':
	if (strEQ(name + 22, "OTNULL")) {	/* CAPI_STAT_API_STREAM_N removed */
#ifdef CAPI_STAT_API_STREAM_NOTNULL
	    return CAPI_STAT_API_STREAM_NOTNULL;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 22, "ULL")) {	/* CAPI_STAT_API_STREAM_N removed */
#ifdef CAPI_STAT_API_STREAM_NULL
	    return CAPI_STAT_API_STREAM_NULL;
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
constant_CAPI_STAT_API_STREAM_(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'B':
	if (strEQ(name + 21, "BAD")) {	/* CAPI_STAT_API_STREAM_ removed */
#ifdef CAPI_STAT_API_STREAM_BAD
	    return CAPI_STAT_API_STREAM_BAD;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_CAPI_STAT_API_STREAM_N(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_ST(char *name, int len, int arg)
{
    if (16 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 4]) {
    case '\0':
	if (strEQ(name + 16, "REAM")) {	/* CAPI_STAT_API_ST removed */
#ifdef CAPI_STAT_API_STREAM
	    return CAPI_STAT_API_STREAM;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 16,"REAM", 4))
	    break;
	return constant_CAPI_STAT_API_STREAM_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_SESSION_N(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'O':
	if (strEQ(name + 23, "OTNULL")) {	/* CAPI_STAT_API_SESSION_N removed */
#ifdef CAPI_STAT_API_SESSION_NOTNULL
	    return CAPI_STAT_API_SESSION_NOTNULL;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 23, "ULL")) {	/* CAPI_STAT_API_SESSION_N removed */
#ifdef CAPI_STAT_API_SESSION_NULL
	    return CAPI_STAT_API_SESSION_NULL;
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
constant_CAPI_STAT_API_SESSION_(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'B':
	if (strEQ(name + 22, "BAD")) {	/* CAPI_STAT_API_SESSION_ removed */
#ifdef CAPI_STAT_API_SESSION_BAD
	    return CAPI_STAT_API_SESSION_BAD;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_CAPI_STAT_API_SESSION_N(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_SE(char *name, int len, int arg)
{
    if (16 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 5]) {
    case '\0':
	if (strEQ(name + 16, "SSION")) {	/* CAPI_STAT_API_SE removed */
#ifdef CAPI_STAT_API_SESSION
	    return CAPI_STAT_API_SESSION;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 16,"SSION", 5))
	    break;
	return constant_CAPI_STAT_API_SESSION_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_S(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case 'E':
	return constant_CAPI_STAT_API_SE(name, len, arg);
    case 'T':
	return constant_CAPI_STAT_API_ST(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_API_C(char *name, int len, int arg)
{
    if (15 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 7]) {
    case '\0':
	if (strEQ(name + 15, "ALLBACK")) {	/* CAPI_STAT_API_C removed */
#ifdef CAPI_STAT_API_CALLBACK
	    return CAPI_STAT_API_CALLBACK;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 15, "ALLBACK_ERROR")) {	/* CAPI_STAT_API_C removed */
#ifdef CAPI_STAT_API_CALLBACK_ERROR
	    return CAPI_STAT_API_CALLBACK_ERROR;
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
constant_CAPI_STAT_API_(char *name, int len, int arg)
{
    switch (name[14 + 0]) {
    case 'B':
	if (strEQ(name + 14, "BADPARAM")) {	/* CAPI_STAT_API_ removed */
#ifdef CAPI_STAT_API_BADPARAM
	    return CAPI_STAT_API_BADPARAM;
#else
	    goto not_there;
#endif
	}
    case 'C':
	return constant_CAPI_STAT_API_C(name, len, arg);
    case 'F':
	if (strEQ(name + 14, "FLAGS")) {	/* CAPI_STAT_API_ removed */
#ifdef CAPI_STAT_API_FLAGS
	    return CAPI_STAT_API_FLAGS;
#else
	    goto not_there;
#endif
	}
    case 'H':
	return constant_CAPI_STAT_API_H(name, len, arg);
    case 'N':
	if (strEQ(name + 14, "NULL")) {	/* CAPI_STAT_API_ removed */
#ifdef CAPI_STAT_API_NULL
	    return CAPI_STAT_API_NULL;
#else
	    goto not_there;
#endif
	}
    case 'P':
	return constant_CAPI_STAT_API_P(name, len, arg);
    case 'S':
	return constant_CAPI_STAT_API_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_A(char *name, int len, int arg)
{
    if (11 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 2]) {
    case '\0':
	if (strEQ(name + 11, "PI")) {	/* CAPI_STAT_A removed */
#ifdef CAPI_STAT_API
	    return CAPI_STAT_API;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 11,"PI", 2))
	    break;
	return constant_CAPI_STAT_API_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SERVICE_N(char *name, int len, int arg)
{
    if (19 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 2]) {
    case '\0':
	if (strEQ(name + 19, "ET")) {	/* CAPI_STAT_SERVICE_N removed */
#ifdef CAPI_STAT_SERVICE_NET
	    return CAPI_STAT_SERVICE_NET;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 19, "ET_TIMEOUT")) {	/* CAPI_STAT_SERVICE_N removed */
#ifdef CAPI_STAT_SERVICE_NET_TIMEOUT
	    return CAPI_STAT_SERVICE_NET_TIMEOUT;
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
constant_CAPI_STAT_SERVICE_FILE_(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'C':
	if (strEQ(name + 23, "CLOSE")) {	/* CAPI_STAT_SERVICE_FILE_ removed */
#ifdef CAPI_STAT_SERVICE_FILE_CLOSE
	    return CAPI_STAT_SERVICE_FILE_CLOSE;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 23, "DELETE")) {	/* CAPI_STAT_SERVICE_FILE_ removed */
#ifdef CAPI_STAT_SERVICE_FILE_DELETE
	    return CAPI_STAT_SERVICE_FILE_DELETE;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 23, "MODE")) {	/* CAPI_STAT_SERVICE_FILE_ removed */
#ifdef CAPI_STAT_SERVICE_FILE_MODE
	    return CAPI_STAT_SERVICE_FILE_MODE;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 23, "OPEN")) {	/* CAPI_STAT_SERVICE_FILE_ removed */
#ifdef CAPI_STAT_SERVICE_FILE_OPEN
	    return CAPI_STAT_SERVICE_FILE_OPEN;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 23, "READ")) {	/* CAPI_STAT_SERVICE_FILE_ removed */
#ifdef CAPI_STAT_SERVICE_FILE_READ
	    return CAPI_STAT_SERVICE_FILE_READ;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 23, "TEMP")) {	/* CAPI_STAT_SERVICE_FILE_ removed */
#ifdef CAPI_STAT_SERVICE_FILE_TEMP
	    return CAPI_STAT_SERVICE_FILE_TEMP;
#else
	    goto not_there;
#endif
	}
    case 'W':
	if (strEQ(name + 23, "WRITE")) {	/* CAPI_STAT_SERVICE_FILE_ removed */
#ifdef CAPI_STAT_SERVICE_FILE_WRITE
	    return CAPI_STAT_SERVICE_FILE_WRITE;
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
constant_CAPI_STAT_SERVICE_F(char *name, int len, int arg)
{
    if (19 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 3]) {
    case '\0':
	if (strEQ(name + 19, "ILE")) {	/* CAPI_STAT_SERVICE_F removed */
#ifdef CAPI_STAT_SERVICE_FILE
	    return CAPI_STAT_SERVICE_FILE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 19,"ILE", 3))
	    break;
	return constant_CAPI_STAT_SERVICE_FILE_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SERVICE_ACE_(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'L':
	if (strEQ(name + 22, "LOAD")) {	/* CAPI_STAT_SERVICE_ACE_ removed */
#ifdef CAPI_STAT_SERVICE_ACE_LOAD
	    return CAPI_STAT_SERVICE_ACE_LOAD;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 22, "SUPPORT")) {	/* CAPI_STAT_SERVICE_ACE_ removed */
#ifdef CAPI_STAT_SERVICE_ACE_SUPPORT
	    return CAPI_STAT_SERVICE_ACE_SUPPORT;
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
constant_CAPI_STAT_SERVICE_A(char *name, int len, int arg)
{
    if (19 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 2]) {
    case '\0':
	if (strEQ(name + 19, "CE")) {	/* CAPI_STAT_SERVICE_A removed */
#ifdef CAPI_STAT_SERVICE_ACE
	    return CAPI_STAT_SERVICE_ACE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 19,"CE", 2))
	    break;
	return constant_CAPI_STAT_SERVICE_ACE_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SERVICE_TI(char *name, int len, int arg)
{
    if (20 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 2]) {
    case '\0':
	if (strEQ(name + 20, "ME")) {	/* CAPI_STAT_SERVICE_TI removed */
#ifdef CAPI_STAT_SERVICE_TIME
	    return CAPI_STAT_SERVICE_TIME;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 20, "ME_GMTIME")) {	/* CAPI_STAT_SERVICE_TI removed */
#ifdef CAPI_STAT_SERVICE_TIME_GMTIME
	    return CAPI_STAT_SERVICE_TIME_GMTIME;
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
constant_CAPI_STAT_SERVICE_T(char *name, int len, int arg)
{
    switch (name[19 + 0]) {
    case 'H':
	if (strEQ(name + 19, "HREAD")) {	/* CAPI_STAT_SERVICE_T removed */
#ifdef CAPI_STAT_SERVICE_THREAD
	    return CAPI_STAT_SERVICE_THREAD;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant_CAPI_STAT_SERVICE_TI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SERVICE_M(char *name, int len, int arg)
{
    if (19 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 2]) {
    case '\0':
	if (strEQ(name + 19, "EM")) {	/* CAPI_STAT_SERVICE_M removed */
#ifdef CAPI_STAT_SERVICE_MEM
	    return CAPI_STAT_SERVICE_MEM;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 19, "EM_ALLOC")) {	/* CAPI_STAT_SERVICE_M removed */
#ifdef CAPI_STAT_SERVICE_MEM_ALLOC
	    return CAPI_STAT_SERVICE_MEM_ALLOC;
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
constant_CAPI_STAT_SERVICE_(char *name, int len, int arg)
{
    switch (name[18 + 0]) {
    case 'A':
	return constant_CAPI_STAT_SERVICE_A(name, len, arg);
    case 'F':
	return constant_CAPI_STAT_SERVICE_F(name, len, arg);
    case 'L':
	if (strEQ(name + 18, "LIBRARY")) {	/* CAPI_STAT_SERVICE_ removed */
#ifdef CAPI_STAT_SERVICE_LIBRARY
	    return CAPI_STAT_SERVICE_LIBRARY;
#else
	    goto not_there;
#endif
	}
    case 'M':
	return constant_CAPI_STAT_SERVICE_M(name, len, arg);
    case 'N':
	return constant_CAPI_STAT_SERVICE_N(name, len, arg);
    case 'T':
	return constant_CAPI_STAT_SERVICE_T(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SER(char *name, int len, int arg)
{
    if (13 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[13 + 4]) {
    case '\0':
	if (strEQ(name + 13, "VICE")) {	/* CAPI_STAT_SER removed */
#ifdef CAPI_STAT_SERVICE
	    return CAPI_STAT_SERVICE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 13,"VICE", 4))
	    break;
	return constant_CAPI_STAT_SERVICE_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SECUR_WRITE_(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'A':
	if (strEQ(name + 22, "AGENDA")) {	/* CAPI_STAT_SECUR_WRITE_ removed */
#ifdef CAPI_STAT_SECUR_WRITE_AGENDA
	    return CAPI_STAT_SECUR_WRITE_AGENDA;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 22, "EVENT")) {	/* CAPI_STAT_SECUR_WRITE_ removed */
#ifdef CAPI_STAT_SECUR_WRITE_EVENT
	    return CAPI_STAT_SECUR_WRITE_EVENT;
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
constant_CAPI_STAT_SECUR_W(char *name, int len, int arg)
{
    if (17 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 4]) {
    case '\0':
	if (strEQ(name + 17, "RITE")) {	/* CAPI_STAT_SECUR_W removed */
#ifdef CAPI_STAT_SECUR_WRITE
	    return CAPI_STAT_SECUR_WRITE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 17,"RITE", 4))
	    break;
	return constant_CAPI_STAT_SECUR_WRITE_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SECUR_READ_(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'A':
	if (strEQ(name + 21, "ALARM")) {	/* CAPI_STAT_SECUR_READ_ removed */
#ifdef CAPI_STAT_SECUR_READ_ALARM
	    return CAPI_STAT_SECUR_READ_ALARM;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 21, "PROPS")) {	/* CAPI_STAT_SECUR_READ_ removed */
#ifdef CAPI_STAT_SECUR_READ_PROPS
	    return CAPI_STAT_SECUR_READ_PROPS;
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
constant_CAPI_STAT_SECUR_R(char *name, int len, int arg)
{
    if (17 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 3]) {
    case '\0':
	if (strEQ(name + 17, "EAD")) {	/* CAPI_STAT_SECUR_R removed */
#ifdef CAPI_STAT_SECUR_READ
	    return CAPI_STAT_SECUR_READ;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 17,"EAD", 3))
	    break;
	return constant_CAPI_STAT_SECUR_READ_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SECUR_SERVER_S(char *name, int len, int arg)
{
    if (24 + 17 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[24 + 17]) {
    case '\0':
	if (strEQ(name + 24, "ET_IDENTITY_SYSOP")) {	/* CAPI_STAT_SECUR_SERVER_S removed */
#ifdef CAPI_STAT_SECUR_SERVER_SET_IDENTITY_SYSOP
	    return CAPI_STAT_SECUR_SERVER_SET_IDENTITY_SYSOP;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 24, "ET_IDENTITY_SYSOP_REMOTE")) {	/* CAPI_STAT_SECUR_SERVER_S removed */
#ifdef CAPI_STAT_SECUR_SERVER_SET_IDENTITY_SYSOP_REMOTE
	    return CAPI_STAT_SECUR_SERVER_SET_IDENTITY_SYSOP_REMOTE;
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
constant_CAPI_STAT_SECUR_SERVER_(char *name, int len, int arg)
{
    switch (name[23 + 0]) {
    case 'L':
	if (strEQ(name + 23, "LICENSE")) {	/* CAPI_STAT_SECUR_SERVER_ removed */
#ifdef CAPI_STAT_SECUR_SERVER_LICENSE
	    return CAPI_STAT_SECUR_SERVER_LICENSE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	return constant_CAPI_STAT_SECUR_SERVER_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SECUR_S(char *name, int len, int arg)
{
    if (17 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 5]) {
    case '\0':
	if (strEQ(name + 17, "ERVER")) {	/* CAPI_STAT_SECUR_S removed */
#ifdef CAPI_STAT_SECUR_SERVER
	    return CAPI_STAT_SECUR_SERVER;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 17,"ERVER", 5))
	    break;
	return constant_CAPI_STAT_SECUR_SERVER_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SECUR_LOGON_LOCKED_(char *name, int len, int arg)
{
    switch (name[29 + 0]) {
    case 'R':
	if (strEQ(name + 29, "RESOURCE")) {	/* CAPI_STAT_SECUR_LOGON_LOCKED_ removed */
#ifdef CAPI_STAT_SECUR_LOGON_LOCKED_RESOURCE
	    return CAPI_STAT_SECUR_LOGON_LOCKED_RESOURCE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 29, "SYSOP")) {	/* CAPI_STAT_SECUR_LOGON_LOCKED_ removed */
#ifdef CAPI_STAT_SECUR_LOGON_LOCKED_SYSOP
	    return CAPI_STAT_SECUR_LOGON_LOCKED_SYSOP;
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
constant_CAPI_STAT_SECUR_LOGON_L(char *name, int len, int arg)
{
    if (23 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[23 + 5]) {
    case '\0':
	if (strEQ(name + 23, "OCKED")) {	/* CAPI_STAT_SECUR_LOGON_L removed */
#ifdef CAPI_STAT_SECUR_LOGON_LOCKED
	    return CAPI_STAT_SECUR_LOGON_LOCKED;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 23,"OCKED", 5))
	    break;
	return constant_CAPI_STAT_SECUR_LOGON_LOCKED_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SECUR_LOGON_(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'A':
	if (strEQ(name + 22, "AUTH")) {	/* CAPI_STAT_SECUR_LOGON_ removed */
#ifdef CAPI_STAT_SECUR_LOGON_AUTH
	    return CAPI_STAT_SECUR_LOGON_AUTH;
#else
	    goto not_there;
#endif
	}
    case 'L':
	return constant_CAPI_STAT_SECUR_LOGON_L(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SECUR_L(char *name, int len, int arg)
{
    if (17 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 4]) {
    case '\0':
	if (strEQ(name + 17, "OGON")) {	/* CAPI_STAT_SECUR_L removed */
#ifdef CAPI_STAT_SECUR_LOGON
	    return CAPI_STAT_SECUR_LOGON;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 17,"OGON", 4))
	    break;
	return constant_CAPI_STAT_SECUR_LOGON_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SECUR_(char *name, int len, int arg)
{
    switch (name[16 + 0]) {
    case 'C':
	if (strEQ(name + 16, "CANTBOOKATTENDEE")) {	/* CAPI_STAT_SECUR_ removed */
#ifdef CAPI_STAT_SECUR_CANTBOOKATTENDEE
	    return CAPI_STAT_SECUR_CANTBOOKATTENDEE;
#else
	    goto not_there;
#endif
	}
    case 'L':
	return constant_CAPI_STAT_SECUR_L(name, len, arg);
    case 'R':
	return constant_CAPI_STAT_SECUR_R(name, len, arg);
    case 'S':
	return constant_CAPI_STAT_SECUR_S(name, len, arg);
    case 'W':
	return constant_CAPI_STAT_SECUR_W(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_SEC(char *name, int len, int arg)
{
    if (13 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[13 + 2]) {
    case '\0':
	if (strEQ(name + 13, "UR")) {	/* CAPI_STAT_SEC removed */
#ifdef CAPI_STAT_SECUR
	    return CAPI_STAT_SECUR;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 13,"UR", 2))
	    break;
	return constant_CAPI_STAT_SECUR_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_S(char *name, int len, int arg)
{
    if (11 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 1]) {
    case 'C':
	if (!strnEQ(name + 11,"E", 1))
	    break;
	return constant_CAPI_STAT_SEC(name, len, arg);
    case 'R':
	if (!strnEQ(name + 11,"E", 1))
	    break;
	return constant_CAPI_STAT_SER(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_C(char *name, int len, int arg)
{
    if (11 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 5]) {
    case '\0':
	if (strEQ(name + 11, "ONFIG")) {	/* CAPI_STAT_C removed */
#ifdef CAPI_STAT_CONFIG
	    return CAPI_STAT_CONFIG;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 11, "ONFIG_CANNOT_OPEN")) {	/* CAPI_STAT_C removed */
#ifdef CAPI_STAT_CONFIG_CANNOT_OPEN
	    return CAPI_STAT_CONFIG_CANNOT_OPEN;
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
constant_CAPI_STAT_LIBRARY_INTERNAL_C(char *name, int len, int arg)
{
    if (28 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[28 + 1]) {
    case 'N':
	if (strEQ(name + 28, "ONTEXT")) {	/* CAPI_STAT_LIBRARY_INTERNAL_C removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_CONTEXT
	    return CAPI_STAT_LIBRARY_INTERNAL_CONTEXT;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 28, "OSMICRAY")) {	/* CAPI_STAT_LIBRARY_INTERNAL_C removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_COSMICRAY
	    return CAPI_STAT_LIBRARY_INTERNAL_COSMICRAY;
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
constant_CAPI_STAT_LIBRARY_INTERNAL_U(char *name, int len, int arg)
{
    if (28 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[28 + 7]) {
    case 'E':
	if (strEQ(name + 28, "NKNOWN_EXCEPTION")) {	/* CAPI_STAT_LIBRARY_INTERNAL_U removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_UNKNOWN_EXCEPTION
	    return CAPI_STAT_LIBRARY_INTERNAL_UNKNOWN_EXCEPTION;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 28, "NKNOWN_LIBRARY_ERRCODE")) {	/* CAPI_STAT_LIBRARY_INTERNAL_U removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_UNKNOWN_LIBRARY_ERRCODE
	    return CAPI_STAT_LIBRARY_INTERNAL_UNKNOWN_LIBRARY_ERRCODE;
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
constant_CAPI_STAT_LIBRARY_INTERNAL_(char *name, int len, int arg)
{
    switch (name[27 + 0]) {
    case 'C':
	return constant_CAPI_STAT_LIBRARY_INTERNAL_C(name, len, arg);
    case 'D':
	if (strEQ(name + 27, "DATA")) {	/* CAPI_STAT_LIBRARY_INTERNAL_ removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_DATA
	    return CAPI_STAT_LIBRARY_INTERNAL_DATA;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 27, "EXPIRY")) {	/* CAPI_STAT_LIBRARY_INTERNAL_ removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_EXPIRY
	    return CAPI_STAT_LIBRARY_INTERNAL_EXPIRY;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 27, "FUNCTION")) {	/* CAPI_STAT_LIBRARY_INTERNAL_ removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_FUNCTION
	    return CAPI_STAT_LIBRARY_INTERNAL_FUNCTION;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 27, "OVERFLOW")) {	/* CAPI_STAT_LIBRARY_INTERNAL_ removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_OVERFLOW
	    return CAPI_STAT_LIBRARY_INTERNAL_OVERFLOW;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 27, "PROTOCOL")) {	/* CAPI_STAT_LIBRARY_INTERNAL_ removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL_PROTOCOL
	    return CAPI_STAT_LIBRARY_INTERNAL_PROTOCOL;
#else
	    goto not_there;
#endif
	}
    case 'U':
	return constant_CAPI_STAT_LIBRARY_INTERNAL_U(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_LIBRARY_IN(char *name, int len, int arg)
{
    if (20 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 6]) {
    case '\0':
	if (strEQ(name + 20, "TERNAL")) {	/* CAPI_STAT_LIBRARY_IN removed */
#ifdef CAPI_STAT_LIBRARY_INTERNAL
	    return CAPI_STAT_LIBRARY_INTERNAL;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 20,"TERNAL", 6))
	    break;
	return constant_CAPI_STAT_LIBRARY_INTERNAL_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_LIBRARY_I(char *name, int len, int arg)
{
    switch (name[19 + 0]) {
    case 'M':
	if (strEQ(name + 19, "MPLEMENTATION")) {	/* CAPI_STAT_LIBRARY_I removed */
#ifdef CAPI_STAT_LIBRARY_IMPLEMENTATION
	    return CAPI_STAT_LIBRARY_IMPLEMENTATION;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_CAPI_STAT_LIBRARY_IN(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_LIBRARY_SERVER_SUPPORT_(char *name, int len, int arg)
{
    switch (name[33 + 0]) {
    case 'C':
	if (strEQ(name + 33, "CHARSET")) {	/* CAPI_STAT_LIBRARY_SERVER_SUPPORT_ removed */
#ifdef CAPI_STAT_LIBRARY_SERVER_SUPPORT_CHARSET
	    return CAPI_STAT_LIBRARY_SERVER_SUPPORT_CHARSET;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 33, "STANDARDS")) {	/* CAPI_STAT_LIBRARY_SERVER_SUPPORT_ removed */
#ifdef CAPI_STAT_LIBRARY_SERVER_SUPPORT_STANDARDS
	    return CAPI_STAT_LIBRARY_SERVER_SUPPORT_STANDARDS;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 33, "UID")) {	/* CAPI_STAT_LIBRARY_SERVER_SUPPORT_ removed */
#ifdef CAPI_STAT_LIBRARY_SERVER_SUPPORT_UID
	    return CAPI_STAT_LIBRARY_SERVER_SUPPORT_UID;
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
constant_CAPI_STAT_LIBRARY_SERVER_S(char *name, int len, int arg)
{
    if (26 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[26 + 6]) {
    case '\0':
	if (strEQ(name + 26, "UPPORT")) {	/* CAPI_STAT_LIBRARY_SERVER_S removed */
#ifdef CAPI_STAT_LIBRARY_SERVER_SUPPORT
	    return CAPI_STAT_LIBRARY_SERVER_SUPPORT;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 26,"UPPORT", 6))
	    break;
	return constant_CAPI_STAT_LIBRARY_SERVER_SUPPORT_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_LIBRARY_SERVER_U(char *name, int len, int arg)
{
    switch (name[26 + 0]) {
    case 'N':
	if (strEQ(name + 26, "NAVAILABLE")) {	/* CAPI_STAT_LIBRARY_SERVER_U removed */
#ifdef CAPI_STAT_LIBRARY_SERVER_UNAVAILABLE
	    return CAPI_STAT_LIBRARY_SERVER_UNAVAILABLE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 26, "SERDATA")) {	/* CAPI_STAT_LIBRARY_SERVER_U removed */
#ifdef CAPI_STAT_LIBRARY_SERVER_USERDATA
	    return CAPI_STAT_LIBRARY_SERVER_USERDATA;
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
constant_CAPI_STAT_LIBRARY_SERVER_(char *name, int len, int arg)
{
    switch (name[25 + 0]) {
    case 'B':
	if (strEQ(name + 25, "BUSY")) {	/* CAPI_STAT_LIBRARY_SERVER_ removed */
#ifdef CAPI_STAT_LIBRARY_SERVER_BUSY
	    return CAPI_STAT_LIBRARY_SERVER_BUSY;
#else
	    goto not_there;
#endif
	}
    case 'S':
	return constant_CAPI_STAT_LIBRARY_SERVER_S(name, len, arg);
    case 'T':
	if (strEQ(name + 25, "TIMEZONE")) {	/* CAPI_STAT_LIBRARY_SERVER_ removed */
#ifdef CAPI_STAT_LIBRARY_SERVER_TIMEZONE
	    return CAPI_STAT_LIBRARY_SERVER_TIMEZONE;
#else
	    goto not_there;
#endif
	}
    case 'U':
	return constant_CAPI_STAT_LIBRARY_SERVER_U(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_LIBRARY_S(char *name, int len, int arg)
{
    if (19 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 5]) {
    case '\0':
	if (strEQ(name + 19, "ERVER")) {	/* CAPI_STAT_LIBRARY_S removed */
#ifdef CAPI_STAT_LIBRARY_SERVER
	    return CAPI_STAT_LIBRARY_SERVER;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 19,"ERVER", 5))
	    break;
	return constant_CAPI_STAT_LIBRARY_SERVER_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_LIBRARY_(char *name, int len, int arg)
{
    switch (name[18 + 0]) {
    case 'I':
	return constant_CAPI_STAT_LIBRARY_I(name, len, arg);
    case 'S':
	return constant_CAPI_STAT_LIBRARY_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_L(char *name, int len, int arg)
{
    if (11 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 6]) {
    case '\0':
	if (strEQ(name + 11, "IBRARY")) {	/* CAPI_STAT_L removed */
#ifdef CAPI_STAT_LIBRARY
	    return CAPI_STAT_LIBRARY;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 11,"IBRARY", 6))
	    break;
	return constant_CAPI_STAT_LIBRARY_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_QUERY_CONDITION_V(char *name, int len, int arg)
{
    if (32 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[32 + 5]) {
    case 'N':
	if (strEQ(name + 32, "ALUE_NULL")) {	/* CAPI_STAT_DATA_QUERY_CONDITION_V removed */
#ifdef CAPI_STAT_DATA_QUERY_CONDITION_VALUE_NULL
	    return CAPI_STAT_DATA_QUERY_CONDITION_VALUE_NULL;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 32, "ALUE_TOO_LONG")) {	/* CAPI_STAT_DATA_QUERY_CONDITION_V removed */
#ifdef CAPI_STAT_DATA_QUERY_CONDITION_VALUE_TOO_LONG
	    return CAPI_STAT_DATA_QUERY_CONDITION_VALUE_TOO_LONG;
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
constant_CAPI_STAT_DATA_QUERY_CONDITION_P(char *name, int len, int arg)
{
    if (32 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[32 + 8]) {
    case 'N':
	if (strEQ(name + 32, "ROPERTY_NULL")) {	/* CAPI_STAT_DATA_QUERY_CONDITION_P removed */
#ifdef CAPI_STAT_DATA_QUERY_CONDITION_PROPERTY_NULL
	    return CAPI_STAT_DATA_QUERY_CONDITION_PROPERTY_NULL;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 32, "ROPERTY_TOO_LONG")) {	/* CAPI_STAT_DATA_QUERY_CONDITION_P removed */
#ifdef CAPI_STAT_DATA_QUERY_CONDITION_PROPERTY_TOO_LONG
	    return CAPI_STAT_DATA_QUERY_CONDITION_PROPERTY_TOO_LONG;
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
constant_CAPI_STAT_DATA_QUERY_C(char *name, int len, int arg)
{
    if (22 + 9 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[22 + 9]) {
    case 'I':
	if (strEQ(name + 22, "ONDITION_ILLEGAL_OPERATOR")) {	/* CAPI_STAT_DATA_QUERY_C removed */
#ifdef CAPI_STAT_DATA_QUERY_CONDITION_ILLEGAL_OPERATOR
	    return CAPI_STAT_DATA_QUERY_CONDITION_ILLEGAL_OPERATOR;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 22, "ONDITION_NULL")) {	/* CAPI_STAT_DATA_QUERY_C removed */
#ifdef CAPI_STAT_DATA_QUERY_CONDITION_NULL
	    return CAPI_STAT_DATA_QUERY_CONDITION_NULL;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (!strnEQ(name + 22,"ONDITION_", 9))
	    break;
	return constant_CAPI_STAT_DATA_QUERY_CONDITION_P(name, len, arg);
    case 'U':
	if (strEQ(name + 22, "ONDITION_UNKNOWN_OPERATOR")) {	/* CAPI_STAT_DATA_QUERY_C removed */
#ifdef CAPI_STAT_DATA_QUERY_CONDITION_UNKNOWN_OPERATOR
	    return CAPI_STAT_DATA_QUERY_CONDITION_UNKNOWN_OPERATOR;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (!strnEQ(name + 22,"ONDITION_", 9))
	    break;
	return constant_CAPI_STAT_DATA_QUERY_CONDITION_V(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_QUERY_(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'C':
	return constant_CAPI_STAT_DATA_QUERY_C(name, len, arg);
    case 'I':
	if (strEQ(name + 21, "ILLEGAL_OPERATOR")) {	/* CAPI_STAT_DATA_QUERY_ removed */
#ifdef CAPI_STAT_DATA_QUERY_ILLEGAL_OPERATOR
	    return CAPI_STAT_DATA_QUERY_ILLEGAL_OPERATOR;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 21, "NULL")) {	/* CAPI_STAT_DATA_QUERY_ removed */
#ifdef CAPI_STAT_DATA_QUERY_NULL
	    return CAPI_STAT_DATA_QUERY_NULL;
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
constant_CAPI_STAT_DATA_Q(char *name, int len, int arg)
{
    if (16 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 4]) {
    case '\0':
	if (strEQ(name + 16, "UERY")) {	/* CAPI_STAT_DATA_Q removed */
#ifdef CAPI_STAT_DATA_QUERY
	    return CAPI_STAT_DATA_QUERY;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 16,"UERY", 4))
	    break;
	return constant_CAPI_STAT_DATA_QUERY_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_R(char *name, int len, int arg)
{
    if (16 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 6]) {
    case '\0':
	if (strEQ(name + 16, "RESULT")) {	/* CAPI_STAT_DATA_R removed */
#ifdef CAPI_STAT_DATA_RRESULT
	    return CAPI_STAT_DATA_RRESULT;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 16, "RESULT_EOR")) {	/* CAPI_STAT_DATA_R removed */
#ifdef CAPI_STAT_DATA_RRESULT_EOR
	    return CAPI_STAT_DATA_RRESULT_EOR;
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
constant_CAPI_STAT_DATA_DATE_(char *name, int len, int arg)
{
    switch (name[20 + 0]) {
    case 'F':
	if (strEQ(name + 20, "FORMAT")) {	/* CAPI_STAT_DATA_DATE_ removed */
#ifdef CAPI_STAT_DATA_DATE_FORMAT
	    return CAPI_STAT_DATA_DATE_FORMAT;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 20, "INVALID")) {	/* CAPI_STAT_DATA_DATE_ removed */
#ifdef CAPI_STAT_DATA_DATE_INVALID
	    return CAPI_STAT_DATA_DATE_INVALID;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 20, "NOT_LOCAL")) {	/* CAPI_STAT_DATA_DATE_ removed */
#ifdef CAPI_STAT_DATA_DATE_NOT_LOCAL
	    return CAPI_STAT_DATA_DATE_NOT_LOCAL;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 20, "OUTOFRANGE")) {	/* CAPI_STAT_DATA_DATE_ removed */
#ifdef CAPI_STAT_DATA_DATE_OUTOFRANGE
	    return CAPI_STAT_DATA_DATE_OUTOFRANGE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 20, "RANGE")) {	/* CAPI_STAT_DATA_DATE_ removed */
#ifdef CAPI_STAT_DATA_DATE_RANGE
	    return CAPI_STAT_DATA_DATE_RANGE;
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
constant_CAPI_STAT_DATA_D(char *name, int len, int arg)
{
    if (16 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 3]) {
    case '\0':
	if (strEQ(name + 16, "ATE")) {	/* CAPI_STAT_DATA_D removed */
#ifdef CAPI_STAT_DATA_DATE
	    return CAPI_STAT_DATA_DATE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 16,"ATE", 3))
	    break;
	return constant_CAPI_STAT_DATA_DATE_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_UID_(char *name, int len, int arg)
{
    switch (name[19 + 0]) {
    case 'A':
	if (strEQ(name + 19, "ALREADYEXISTS")) {	/* CAPI_STAT_DATA_UID_ removed */
#ifdef CAPI_STAT_DATA_UID_ALREADYEXISTS
	    return CAPI_STAT_DATA_UID_ALREADYEXISTS;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 19, "FORMAT")) {	/* CAPI_STAT_DATA_UID_ removed */
#ifdef CAPI_STAT_DATA_UID_FORMAT
	    return CAPI_STAT_DATA_UID_FORMAT;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 19, "MULTIPLEMATCHES")) {	/* CAPI_STAT_DATA_UID_ removed */
#ifdef CAPI_STAT_DATA_UID_MULTIPLEMATCHES
	    return CAPI_STAT_DATA_UID_MULTIPLEMATCHES;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 19, "NOTFOUND")) {	/* CAPI_STAT_DATA_UID_ removed */
#ifdef CAPI_STAT_DATA_UID_NOTFOUND
	    return CAPI_STAT_DATA_UID_NOTFOUND;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 19, "RECURRENCE")) {	/* CAPI_STAT_DATA_UID_ removed */
#ifdef CAPI_STAT_DATA_UID_RECURRENCE
	    return CAPI_STAT_DATA_UID_RECURRENCE;
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
constant_CAPI_STAT_DATA_UI(char *name, int len, int arg)
{
    if (17 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 1]) {
    case '\0':
	if (strEQ(name + 17, "D")) {	/* CAPI_STAT_DATA_UI removed */
#ifdef CAPI_STAT_DATA_UID
	    return CAPI_STAT_DATA_UID;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 17,"D", 1))
	    break;
	return constant_CAPI_STAT_DATA_UID_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_USERID_EXT_N(char *name, int len, int arg)
{
    if (27 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[27 + 1]) {
    case 'D':
	if (strEQ(name + 27, "ODE")) {	/* CAPI_STAT_DATA_USERID_EXT_N removed */
#ifdef CAPI_STAT_DATA_USERID_EXT_NODE
	    return CAPI_STAT_DATA_USERID_EXT_NODE;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 27, "ONE")) {	/* CAPI_STAT_DATA_USERID_EXT_N removed */
#ifdef CAPI_STAT_DATA_USERID_EXT_NONE
	    return CAPI_STAT_DATA_USERID_EXT_NONE;
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
constant_CAPI_STAT_DATA_USERID_EXT_(char *name, int len, int arg)
{
    switch (name[26 + 0]) {
    case 'C':
	if (strEQ(name + 26, "CONFLICT")) {	/* CAPI_STAT_DATA_USERID_EXT_ removed */
#ifdef CAPI_STAT_DATA_USERID_EXT_CONFLICT
	    return CAPI_STAT_DATA_USERID_EXT_CONFLICT;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 26, "FORMAT")) {	/* CAPI_STAT_DATA_USERID_EXT_ removed */
#ifdef CAPI_STAT_DATA_USERID_EXT_FORMAT
	    return CAPI_STAT_DATA_USERID_EXT_FORMAT;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 26, "INIFILE")) {	/* CAPI_STAT_DATA_USERID_EXT_ removed */
#ifdef CAPI_STAT_DATA_USERID_EXT_INIFILE
	    return CAPI_STAT_DATA_USERID_EXT_INIFILE;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 26, "MANY")) {	/* CAPI_STAT_DATA_USERID_EXT_ removed */
#ifdef CAPI_STAT_DATA_USERID_EXT_MANY
	    return CAPI_STAT_DATA_USERID_EXT_MANY;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_CAPI_STAT_DATA_USERID_EXT_N(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_USERID_E(char *name, int len, int arg)
{
    if (23 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[23 + 2]) {
    case '\0':
	if (strEQ(name + 23, "XT")) {	/* CAPI_STAT_DATA_USERID_E removed */
#ifdef CAPI_STAT_DATA_USERID_EXT
	    return CAPI_STAT_DATA_USERID_EXT;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 23,"XT", 2))
	    break;
	return constant_CAPI_STAT_DATA_USERID_EXT_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_USERID_(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'E':
	return constant_CAPI_STAT_DATA_USERID_E(name, len, arg);
    case 'F':
	if (strEQ(name + 22, "FORMAT")) {	/* CAPI_STAT_DATA_USERID_ removed */
#ifdef CAPI_STAT_DATA_USERID_FORMAT
	    return CAPI_STAT_DATA_USERID_FORMAT;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 22, "ID")) {	/* CAPI_STAT_DATA_USERID_ removed */
#ifdef CAPI_STAT_DATA_USERID_ID
	    return CAPI_STAT_DATA_USERID_ID;
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
constant_CAPI_STAT_DATA_US(char *name, int len, int arg)
{
    if (17 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 4]) {
    case '\0':
	if (strEQ(name + 17, "ERID")) {	/* CAPI_STAT_DATA_US removed */
#ifdef CAPI_STAT_DATA_USERID
	    return CAPI_STAT_DATA_USERID;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 17,"ERID", 4))
	    break;
	return constant_CAPI_STAT_DATA_USERID_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_U(char *name, int len, int arg)
{
    switch (name[16 + 0]) {
    case 'I':
	return constant_CAPI_STAT_DATA_UI(name, len, arg);
    case 'S':
	return constant_CAPI_STAT_DATA_US(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_EM(char *name, int len, int arg)
{
    if (17 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 3]) {
    case '\0':
	if (strEQ(name + 17, "AIL")) {	/* CAPI_STAT_DATA_EM removed */
#ifdef CAPI_STAT_DATA_EMAIL
	    return CAPI_STAT_DATA_EMAIL;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 17, "AIL_NOTSET")) {	/* CAPI_STAT_DATA_EM removed */
#ifdef CAPI_STAT_DATA_EMAIL_NOTSET
	    return CAPI_STAT_DATA_EMAIL_NOTSET;
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
constant_CAPI_STAT_DATA_E(char *name, int len, int arg)
{
    switch (name[16 + 0]) {
    case 'M':
	return constant_CAPI_STAT_DATA_EM(name, len, arg);
    case 'N':
	if (strEQ(name + 16, "NCODING")) {	/* CAPI_STAT_DATA_E removed */
#ifdef CAPI_STAT_DATA_ENCODING
	    return CAPI_STAT_DATA_ENCODING;
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
constant_CAPI_STAT_DATA_VCARD_PA(char *name, int len, int arg)
{
    if (23 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[23 + 3]) {
    case 'E':
	if (strEQ(name + 23, "RAMEXTRA")) {	/* CAPI_STAT_DATA_VCARD_PA removed */
#ifdef CAPI_STAT_DATA_VCARD_PARAMEXTRA
	    return CAPI_STAT_DATA_VCARD_PARAMEXTRA;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 23, "RAMMISSING")) {	/* CAPI_STAT_DATA_VCARD_PA removed */
#ifdef CAPI_STAT_DATA_VCARD_PARAMMISSING
	    return CAPI_STAT_DATA_VCARD_PARAMMISSING;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 23, "RAMNAME")) {	/* CAPI_STAT_DATA_VCARD_PA removed */
#ifdef CAPI_STAT_DATA_VCARD_PARAMNAME
	    return CAPI_STAT_DATA_VCARD_PARAMNAME;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 23, "RAMVALUE")) {	/* CAPI_STAT_DATA_VCARD_PA removed */
#ifdef CAPI_STAT_DATA_VCARD_PARAMVALUE
	    return CAPI_STAT_DATA_VCARD_PARAMVALUE;
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
constant_CAPI_STAT_DATA_VCARD_PR(char *name, int len, int arg)
{
    if (23 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[23 + 2]) {
    case 'E':
	if (strEQ(name + 23, "OPEXTRA")) {	/* CAPI_STAT_DATA_VCARD_PR removed */
#ifdef CAPI_STAT_DATA_VCARD_PROPEXTRA
	    return CAPI_STAT_DATA_VCARD_PROPEXTRA;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 23, "OPMISSING")) {	/* CAPI_STAT_DATA_VCARD_PR removed */
#ifdef CAPI_STAT_DATA_VCARD_PROPMISSING
	    return CAPI_STAT_DATA_VCARD_PROPMISSING;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 23, "OPNAME")) {	/* CAPI_STAT_DATA_VCARD_PR removed */
#ifdef CAPI_STAT_DATA_VCARD_PROPNAME
	    return CAPI_STAT_DATA_VCARD_PROPNAME;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 23, "OPVALUE")) {	/* CAPI_STAT_DATA_VCARD_PR removed */
#ifdef CAPI_STAT_DATA_VCARD_PROPVALUE
	    return CAPI_STAT_DATA_VCARD_PROPVALUE;
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
constant_CAPI_STAT_DATA_VCARD_P(char *name, int len, int arg)
{
    switch (name[22 + 0]) {
    case 'A':
	return constant_CAPI_STAT_DATA_VCARD_PA(name, len, arg);
    case 'R':
	return constant_CAPI_STAT_DATA_VCARD_PR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_VCARD_(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'C':
	if (strEQ(name + 21, "COMPNAME")) {	/* CAPI_STAT_DATA_VCARD_ removed */
#ifdef CAPI_STAT_DATA_VCARD_COMPNAME
	    return CAPI_STAT_DATA_VCARD_COMPNAME;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 21, "DUPERROR")) {	/* CAPI_STAT_DATA_VCARD_ removed */
#ifdef CAPI_STAT_DATA_VCARD_DUPERROR
	    return CAPI_STAT_DATA_VCARD_DUPERROR;
#else
	    goto not_there;
#endif
	}
    case 'P':
	return constant_CAPI_STAT_DATA_VCARD_P(name, len, arg);
    case 'V':
	if (strEQ(name + 21, "VERSION_UNSUPPORTED")) {	/* CAPI_STAT_DATA_VCARD_ removed */
#ifdef CAPI_STAT_DATA_VCARD_VERSION_UNSUPPORTED
	    return CAPI_STAT_DATA_VCARD_VERSION_UNSUPPORTED;
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
constant_CAPI_STAT_DATA_V(char *name, int len, int arg)
{
    if (16 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 4]) {
    case '\0':
	if (strEQ(name + 16, "CARD")) {	/* CAPI_STAT_DATA_V removed */
#ifdef CAPI_STAT_DATA_VCARD
	    return CAPI_STAT_DATA_VCARD;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 16,"CARD", 4))
	    break;
	return constant_CAPI_STAT_DATA_VCARD_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_HOSTNAME_(char *name, int len, int arg)
{
    switch (name[24 + 0]) {
    case 'F':
	if (strEQ(name + 24, "FORMAT")) {	/* CAPI_STAT_DATA_HOSTNAME_ removed */
#ifdef CAPI_STAT_DATA_HOSTNAME_FORMAT
	    return CAPI_STAT_DATA_HOSTNAME_FORMAT;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 24, "HOST")) {	/* CAPI_STAT_DATA_HOSTNAME_ removed */
#ifdef CAPI_STAT_DATA_HOSTNAME_HOST
	    return CAPI_STAT_DATA_HOSTNAME_HOST;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 24, "SERVER")) {	/* CAPI_STAT_DATA_HOSTNAME_ removed */
#ifdef CAPI_STAT_DATA_HOSTNAME_SERVER
	    return CAPI_STAT_DATA_HOSTNAME_SERVER;
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
constant_CAPI_STAT_DATA_H(char *name, int len, int arg)
{
    if (16 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 7]) {
    case '\0':
	if (strEQ(name + 16, "OSTNAME")) {	/* CAPI_STAT_DATA_H removed */
#ifdef CAPI_STAT_DATA_HOSTNAME
	    return CAPI_STAT_DATA_HOSTNAME;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 16,"OSTNAME", 7))
	    break;
	return constant_CAPI_STAT_DATA_HOSTNAME_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_ICAL_N(char *name, int len, int arg)
{
    if (21 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[21 + 1]) {
    case 'A':
	if (strEQ(name + 21, "OATTENDEES")) {	/* CAPI_STAT_DATA_ICAL_N removed */
#ifdef CAPI_STAT_DATA_ICAL_NOATTENDEES
	    return CAPI_STAT_DATA_ICAL_NOATTENDEES;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 21, "ONE")) {	/* CAPI_STAT_DATA_ICAL_N removed */
#ifdef CAPI_STAT_DATA_ICAL_NONE
	    return CAPI_STAT_DATA_ICAL_NONE;
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
constant_CAPI_STAT_DATA_ICAL_PA(char *name, int len, int arg)
{
    if (22 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[22 + 3]) {
    case 'E':
	if (strEQ(name + 22, "RAMEXTRA")) {	/* CAPI_STAT_DATA_ICAL_PA removed */
#ifdef CAPI_STAT_DATA_ICAL_PARAMEXTRA
	    return CAPI_STAT_DATA_ICAL_PARAMEXTRA;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 22, "RAMMISSING")) {	/* CAPI_STAT_DATA_ICAL_PA removed */
#ifdef CAPI_STAT_DATA_ICAL_PARAMMISSING
	    return CAPI_STAT_DATA_ICAL_PARAMMISSING;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 22, "RAMNAME")) {	/* CAPI_STAT_DATA_ICAL_PA removed */
#ifdef CAPI_STAT_DATA_ICAL_PARAMNAME
	    return CAPI_STAT_DATA_ICAL_PARAMNAME;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 22, "RAMVALUE")) {	/* CAPI_STAT_DATA_ICAL_PA removed */
#ifdef CAPI_STAT_DATA_ICAL_PARAMVALUE
	    return CAPI_STAT_DATA_ICAL_PARAMVALUE;
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
constant_CAPI_STAT_DATA_ICAL_PR(char *name, int len, int arg)
{
    if (22 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[22 + 2]) {
    case 'E':
	if (strEQ(name + 22, "OPEXTRA")) {	/* CAPI_STAT_DATA_ICAL_PR removed */
#ifdef CAPI_STAT_DATA_ICAL_PROPEXTRA
	    return CAPI_STAT_DATA_ICAL_PROPEXTRA;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 22, "OPMISSING")) {	/* CAPI_STAT_DATA_ICAL_PR removed */
#ifdef CAPI_STAT_DATA_ICAL_PROPMISSING
	    return CAPI_STAT_DATA_ICAL_PROPMISSING;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 22, "OPNAME")) {	/* CAPI_STAT_DATA_ICAL_PR removed */
#ifdef CAPI_STAT_DATA_ICAL_PROPNAME
	    return CAPI_STAT_DATA_ICAL_PROPNAME;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 22, "OPVALUE")) {	/* CAPI_STAT_DATA_ICAL_PR removed */
#ifdef CAPI_STAT_DATA_ICAL_PROPVALUE
	    return CAPI_STAT_DATA_ICAL_PROPVALUE;
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
constant_CAPI_STAT_DATA_ICAL_P(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'A':
	return constant_CAPI_STAT_DATA_ICAL_PA(name, len, arg);
    case 'R':
	return constant_CAPI_STAT_DATA_ICAL_PR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_ICAL_CO(char *name, int len, int arg)
{
    if (22 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[22 + 2]) {
    case 'E':
	if (strEQ(name + 22, "MPEXTRA")) {	/* CAPI_STAT_DATA_ICAL_CO removed */
#ifdef CAPI_STAT_DATA_ICAL_COMPEXTRA
	    return CAPI_STAT_DATA_ICAL_COMPEXTRA;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 22, "MPMISSING")) {	/* CAPI_STAT_DATA_ICAL_CO removed */
#ifdef CAPI_STAT_DATA_ICAL_COMPMISSING
	    return CAPI_STAT_DATA_ICAL_COMPMISSING;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 22, "MPNAME")) {	/* CAPI_STAT_DATA_ICAL_CO removed */
#ifdef CAPI_STAT_DATA_ICAL_COMPNAME
	    return CAPI_STAT_DATA_ICAL_COMPNAME;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 22, "MPVALUE")) {	/* CAPI_STAT_DATA_ICAL_CO removed */
#ifdef CAPI_STAT_DATA_ICAL_COMPVALUE
	    return CAPI_STAT_DATA_ICAL_COMPVALUE;
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
constant_CAPI_STAT_DATA_ICAL_C(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'A':
	if (strEQ(name + 21, "ANTMODIFYRRULE")) {	/* CAPI_STAT_DATA_ICAL_C removed */
#ifdef CAPI_STAT_DATA_ICAL_CANTMODIFYRRULE
	    return CAPI_STAT_DATA_ICAL_CANTMODIFYRRULE;
#else
	    goto not_there;
#endif
	}
    case 'O':
	return constant_CAPI_STAT_DATA_ICAL_CO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_ICAL_M(char *name, int len, int arg)
{
    if (21 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[21 + 6]) {
    case 'R':
	if (strEQ(name + 21, "ISSINGRECURID")) {	/* CAPI_STAT_DATA_ICAL_M removed */
#ifdef CAPI_STAT_DATA_ICAL_MISSINGRECURID
	    return CAPI_STAT_DATA_ICAL_MISSINGRECURID;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 21, "ISSING_UID")) {	/* CAPI_STAT_DATA_ICAL_M removed */
#ifdef CAPI_STAT_DATA_ICAL_MISSING_UID
	    return CAPI_STAT_DATA_ICAL_MISSING_UID;
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
constant_CAPI_STAT_DATA_ICAL_(char *name, int len, int arg)
{
    switch (name[20 + 0]) {
    case 'C':
	return constant_CAPI_STAT_DATA_ICAL_C(name, len, arg);
    case 'F':
	if (strEQ(name + 20, "FOLDING")) {	/* CAPI_STAT_DATA_ICAL_ removed */
#ifdef CAPI_STAT_DATA_ICAL_FOLDING
	    return CAPI_STAT_DATA_ICAL_FOLDING;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 20, "IMPLEMENT")) {	/* CAPI_STAT_DATA_ICAL_ removed */
#ifdef CAPI_STAT_DATA_ICAL_IMPLEMENT
	    return CAPI_STAT_DATA_ICAL_IMPLEMENT;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 20, "LINEOVERFLOW")) {	/* CAPI_STAT_DATA_ICAL_ removed */
#ifdef CAPI_STAT_DATA_ICAL_LINEOVERFLOW
	    return CAPI_STAT_DATA_ICAL_LINEOVERFLOW;
#else
	    goto not_there;
#endif
	}
    case 'M':
	return constant_CAPI_STAT_DATA_ICAL_M(name, len, arg);
    case 'N':
	return constant_CAPI_STAT_DATA_ICAL_N(name, len, arg);
    case 'O':
	if (strEQ(name + 20, "OVERFLOW")) {	/* CAPI_STAT_DATA_ICAL_ removed */
#ifdef CAPI_STAT_DATA_ICAL_OVERFLOW
	    return CAPI_STAT_DATA_ICAL_OVERFLOW;
#else
	    goto not_there;
#endif
	}
    case 'P':
	return constant_CAPI_STAT_DATA_ICAL_P(name, len, arg);
    case 'R':
	if (strEQ(name + 20, "RECURMODE")) {	/* CAPI_STAT_DATA_ICAL_ removed */
#ifdef CAPI_STAT_DATA_ICAL_RECURMODE
	    return CAPI_STAT_DATA_ICAL_RECURMODE;
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
constant_CAPI_STAT_DATA_I(char *name, int len, int arg)
{
    if (16 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 3]) {
    case '\0':
	if (strEQ(name + 16, "CAL")) {	/* CAPI_STAT_DATA_I removed */
#ifdef CAPI_STAT_DATA_ICAL
	    return CAPI_STAT_DATA_ICAL;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 16,"CAL", 3))
	    break;
	return constant_CAPI_STAT_DATA_ICAL_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_MIME_N(char *name, int len, int arg)
{
    if (21 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[21 + 1]) {
    case 'I':
	if (strEQ(name + 21, "OICAL")) {	/* CAPI_STAT_DATA_MIME_N removed */
#ifdef CAPI_STAT_DATA_MIME_NOICAL
	    return CAPI_STAT_DATA_MIME_NOICAL;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 21, "ONE")) {	/* CAPI_STAT_DATA_MIME_N removed */
#ifdef CAPI_STAT_DATA_MIME_NONE
	    return CAPI_STAT_DATA_MIME_NONE;
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
constant_CAPI_STAT_DATA_MIME_C(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'H':
	if (strEQ(name + 21, "HARSET")) {	/* CAPI_STAT_DATA_MIME_C removed */
#ifdef CAPI_STAT_DATA_MIME_CHARSET
	    return CAPI_STAT_DATA_MIME_CHARSET;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 21, "OMMENT")) {	/* CAPI_STAT_DATA_MIME_C removed */
#ifdef CAPI_STAT_DATA_MIME_COMMENT
	    return CAPI_STAT_DATA_MIME_COMMENT;
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
constant_CAPI_STAT_DATA_MIME_I(char *name, int len, int arg)
{
    if (21 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[21 + 8]) {
    case '\0':
	if (strEQ(name + 21, "MPLEMENT")) {	/* CAPI_STAT_DATA_MIME_I removed */
#ifdef CAPI_STAT_DATA_MIME_IMPLEMENT
	    return CAPI_STAT_DATA_MIME_IMPLEMENT;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 21, "MPLEMENT_NESTING")) {	/* CAPI_STAT_DATA_MIME_I removed */
#ifdef CAPI_STAT_DATA_MIME_IMPLEMENT_NESTING
	    return CAPI_STAT_DATA_MIME_IMPLEMENT_NESTING;
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
constant_CAPI_STAT_DATA_MIME_(char *name, int len, int arg)
{
    switch (name[20 + 0]) {
    case 'C':
	return constant_CAPI_STAT_DATA_MIME_C(name, len, arg);
    case 'E':
	if (strEQ(name + 20, "ENCODING")) {	/* CAPI_STAT_DATA_MIME_ removed */
#ifdef CAPI_STAT_DATA_MIME_ENCODING
	    return CAPI_STAT_DATA_MIME_ENCODING;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 20, "HEADER")) {	/* CAPI_STAT_DATA_MIME_ removed */
#ifdef CAPI_STAT_DATA_MIME_HEADER
	    return CAPI_STAT_DATA_MIME_HEADER;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant_CAPI_STAT_DATA_MIME_I(name, len, arg);
    case 'L':
	if (strEQ(name + 20, "LENGTH")) {	/* CAPI_STAT_DATA_MIME_ removed */
#ifdef CAPI_STAT_DATA_MIME_LENGTH
	    return CAPI_STAT_DATA_MIME_LENGTH;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_CAPI_STAT_DATA_MIME_N(name, len, arg);
    case 'O':
	if (strEQ(name + 20, "OVERFLOW")) {	/* CAPI_STAT_DATA_MIME_ removed */
#ifdef CAPI_STAT_DATA_MIME_OVERFLOW
	    return CAPI_STAT_DATA_MIME_OVERFLOW;
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
constant_CAPI_STAT_DATA_M(char *name, int len, int arg)
{
    if (16 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 3]) {
    case '\0':
	if (strEQ(name + 16, "IME")) {	/* CAPI_STAT_DATA_M removed */
#ifdef CAPI_STAT_DATA_MIME
	    return CAPI_STAT_DATA_MIME;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 16,"IME", 3))
	    break;
	return constant_CAPI_STAT_DATA_MIME_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_DATA_(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case 'C':
	if (strEQ(name + 15, "COOKIE")) {	/* CAPI_STAT_DATA_ removed */
#ifdef CAPI_STAT_DATA_COOKIE
	    return CAPI_STAT_DATA_COOKIE;
#else
	    goto not_there;
#endif
	}
    case 'D':
	return constant_CAPI_STAT_DATA_D(name, len, arg);
    case 'E':
	return constant_CAPI_STAT_DATA_E(name, len, arg);
    case 'H':
	return constant_CAPI_STAT_DATA_H(name, len, arg);
    case 'I':
	return constant_CAPI_STAT_DATA_I(name, len, arg);
    case 'M':
	return constant_CAPI_STAT_DATA_M(name, len, arg);
    case 'Q':
	return constant_CAPI_STAT_DATA_Q(name, len, arg);
    case 'R':
	return constant_CAPI_STAT_DATA_R(name, len, arg);
    case 'S':
	if (strEQ(name + 15, "SERVER")) {	/* CAPI_STAT_DATA_ removed */
#ifdef CAPI_STAT_DATA_SERVER
	    return CAPI_STAT_DATA_SERVER;
#else
	    goto not_there;
#endif
	}
    case 'U':
	return constant_CAPI_STAT_DATA_U(name, len, arg);
    case 'V':
	return constant_CAPI_STAT_DATA_V(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_D(char *name, int len, int arg)
{
    if (11 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 3]) {
    case '\0':
	if (strEQ(name + 11, "ATA")) {	/* CAPI_STAT_D removed */
#ifdef CAPI_STAT_DATA
	    return CAPI_STAT_DATA;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 11,"ATA", 3))
	    break;
	return constant_CAPI_STAT_DATA_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STAT_(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'A':
	return constant_CAPI_STAT_A(name, len, arg);
    case 'C':
	return constant_CAPI_STAT_C(name, len, arg);
    case 'D':
	return constant_CAPI_STAT_D(name, len, arg);
    case 'L':
	return constant_CAPI_STAT_L(name, len, arg);
    case 'O':
	if (strEQ(name + 10, "OK")) {	/* CAPI_STAT_ removed */
#ifdef CAPI_STAT_OK
	    return CAPI_STAT_OK;
#else
	    goto not_there;
#endif
	}
    case 'S':
	return constant_CAPI_STAT_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_STATMASK_3(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case '\0':
	if (strEQ(name + 15, "")) {	/* CAPI_STATMASK_3 removed */
#ifdef CAPI_STATMASK_3
	    return CAPI_STATMASK_3;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 15, "_FIELD")) {	/* CAPI_STATMASK_3 removed */
#ifdef CAPI_STATMASK_3_FIELD
	    return CAPI_STATMASK_3_FIELD;
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
constant_CAPI_STATMASK_C(char *name, int len, int arg)
{
    if (15 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 4]) {
    case '\0':
	if (strEQ(name + 15, "LASS")) {	/* CAPI_STATMASK_C removed */
#ifdef CAPI_STATMASK_CLASS
	    return CAPI_STATMASK_CLASS;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 15, "LASS_FIELD")) {	/* CAPI_STATMASK_C removed */
#ifdef CAPI_STATMASK_CLASS_FIELD
	    return CAPI_STATMASK_CLASS_FIELD;
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
constant_CAPI_STATMASK_4(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case '\0':
	if (strEQ(name + 15, "")) {	/* CAPI_STATMASK_4 removed */
#ifdef CAPI_STATMASK_4
	    return CAPI_STATMASK_4;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 15, "_FIELD")) {	/* CAPI_STATMASK_4 removed */
#ifdef CAPI_STATMASK_4_FIELD
	    return CAPI_STATMASK_4_FIELD;
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
constant_CAPI_STATMASK_5(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case '\0':
	if (strEQ(name + 15, "")) {	/* CAPI_STATMASK_5 removed */
#ifdef CAPI_STATMASK_5
	    return CAPI_STATMASK_5;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 15, "_FIELD")) {	/* CAPI_STATMASK_5 removed */
#ifdef CAPI_STATMASK_5_FIELD
	    return CAPI_STATMASK_5_FIELD;
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
constant_CAPI_STATMA(char *name, int len, int arg)
{
    if (11 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 3]) {
    case '3':
	if (!strnEQ(name + 11,"SK_", 3))
	    break;
	return constant_CAPI_STATMASK_3(name, len, arg);
    case '4':
	if (!strnEQ(name + 11,"SK_", 3))
	    break;
	return constant_CAPI_STATMASK_4(name, len, arg);
    case '5':
	if (!strnEQ(name + 11,"SK_", 3))
	    break;
	return constant_CAPI_STATMASK_5(name, len, arg);
    case 'C':
	if (!strnEQ(name + 11,"SK_", 3))
	    break;
	return constant_CAPI_STATMASK_C(name, len, arg);
    case 'M':
	if (strEQ(name + 11, "SK_MODE_FIELD")) {	/* CAPI_STATMA removed */
#ifdef CAPI_STATMASK_MODE_FIELD
	    return CAPI_STATMASK_MODE_FIELD;
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
constant_CAPI_STATM(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'A':
	return constant_CAPI_STATMA(name, len, arg);
    case 'O':
	if (strEQ(name + 10, "ODE_FATAL")) {	/* CAPI_STATM removed */
#ifdef CAPI_STATMODE_FATAL
	    return CAPI_STATMODE_FATAL;
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
constant_CAPI_STA(char *name, int len, int arg)
{
    if (8 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 1]) {
    case 'M':
	if (!strnEQ(name + 8,"T", 1))
	    break;
	return constant_CAPI_STATM(name, len, arg);
    case '_':
	if (!strnEQ(name + 8,"T", 1))
	    break;
	return constant_CAPI_STAT_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_ST(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'A':
	return constant_CAPI_STA(name, len, arg);
    case 'O':
	return constant_CAPI_STO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_S(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'E':
	if (strEQ(name + 6, "ESSION_INITIALIZER")) {	/* CAPI_S removed */
#ifdef CAPI_SESSION_INITIALIZER
	    return CAPI_SESSION_INITIALIZER;
#else
	    goto not_there;
#endif
	}
    case 'T':
	return constant_CAPI_ST(name, len, arg);
    case 'e':
	return constant_CAPI_Se(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_CAPAB_A(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case 'B':
	if (strEQ(name + 12, "BOUT_BOX")) {	/* CAPI_CAPAB_A removed */
#ifdef CAPI_CAPAB_ABOUT_BOX
	    return CAPI_CAPAB_ABOUT_BOX;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 12, "UTH")) {	/* CAPI_CAPAB_A removed */
#ifdef CAPI_CAPAB_AUTH
	    return CAPI_CAPAB_AUTH;
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
constant_CAPI_CAPAB_C(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case 'A':
	if (strEQ(name + 12, "API_VERSION")) {	/* CAPI_CAPAB_C removed */
#ifdef CAPI_CAPAB_CAPI_VERSION
	    return CAPI_CAPAB_CAPI_VERSION;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 12, "OMP")) {	/* CAPI_CAPAB_C removed */
#ifdef CAPI_CAPAB_COMP
	    return CAPI_CAPAB_COMP;
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
constant_CAPI_CAPAB_U(char *name, int len, int arg)
{
    if (12 + 16 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 16]) {
    case 'C':
	if (strEQ(name + 12, "NSUPPORTED_ICAL_COMP")) {	/* CAPI_CAPAB_U removed */
#ifdef CAPI_CAPAB_UNSUPPORTED_ICAL_COMP
	    return CAPI_CAPAB_UNSUPPORTED_ICAL_COMP;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 12, "NSUPPORTED_ICAL_PROP")) {	/* CAPI_CAPAB_U removed */
#ifdef CAPI_CAPAB_UNSUPPORTED_ICAL_PROP
	    return CAPI_CAPAB_UNSUPPORTED_ICAL_PROP;
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
constant_CAPI_CAP(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case 'A':
	if (!strnEQ(name + 8,"AB_", 3))
	    break;
	return constant_CAPI_CAPAB_A(name, len, arg);
    case 'C':
	if (!strnEQ(name + 8,"AB_", 3))
	    break;
	return constant_CAPI_CAPAB_C(name, len, arg);
    case 'E':
	if (strEQ(name + 8, "AB_ENCR")) {	/* CAPI_CAP removed */
#ifdef CAPI_CAPAB_ENCR
	    return CAPI_CAPAB_ENCR;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 8, "AB_MAXDATE")) {	/* CAPI_CAP removed */
#ifdef CAPI_CAPAB_MAXDATE
	    return CAPI_CAPAB_MAXDATE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 8, "AB_SERVER_VERSION")) {	/* CAPI_CAP removed */
#ifdef CAPI_CAPAB_SERVER_VERSION
	    return CAPI_CAPAB_SERVER_VERSION;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (!strnEQ(name + 8,"AB_", 3))
	    break;
	return constant_CAPI_CAPAB_U(name, len, arg);
    case 'V':
	if (strEQ(name + 8, "AB_VERSION")) {	/* CAPI_CAP removed */
#ifdef CAPI_CAPAB_VERSION
	    return CAPI_CAPAB_VERSION;
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
constant_CAPI_CALLBACK_CA(char *name, int len, int arg)
{
    if (16 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 3]) {
    case 'M':
	if (strEQ(name + 16, "NT_MALLOC_ERR")) {	/* CAPI_CALLBACK_CA removed */
#ifdef CAPI_CALLBACK_CANT_MALLOC_ERR
	    return CAPI_CALLBACK_CANT_MALLOC_ERR;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 16, "NT_REALLOC_ERR")) {	/* CAPI_CALLBACK_CA removed */
#ifdef CAPI_CALLBACK_CANT_REALLOC_ERR
	    return CAPI_CALLBACK_CANT_REALLOC_ERR;
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
constant_CAPI_CALLBACK_C(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case 'A':
	return constant_CAPI_CALLBACK_CA(name, len, arg);
    case 'O':
	if (strEQ(name + 15, "ONTINUE")) {	/* CAPI_CALLBACK_C removed */
#ifdef CAPI_CALLBACK_CONTINUE
	    return CAPI_CALLBACK_CONTINUE;
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
constant_CAPI_CAL(char *name, int len, int arg)
{
    if (8 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 6]) {
    case 'C':
	if (!strnEQ(name + 8,"LBACK_", 6))
	    break;
	return constant_CAPI_CALLBACK_C(name, len, arg);
    case 'D':
	if (strEQ(name + 8, "LBACK_DONE")) {	/* CAPI_CAL removed */
#ifdef CAPI_CALLBACK_DONE
	    return CAPI_CALLBACK_DONE;
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
constant_CAPI_CA(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'L':
	return constant_CAPI_CAL(name, len, arg);
    case 'P':
	return constant_CAPI_CAP(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_Cr(char *name, int len, int arg)
{
    if (7 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 4]) {
    case 'C':
	if (strEQ(name + 7, "eateCallbackStream")) {	/* CAPI_Cr removed */
#ifdef CAPI_CreateCallbackStream
	    return (IV)CAPI_CreateCallbackStream;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 7, "eateFileStreamFromFilenames")) {	/* CAPI_Cr removed */
#ifdef CAPI_CreateFileStreamFromFilenames
	    return (IV)CAPI_CreateFileStreamFromFilenames;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 7, "eateMemoryStream")) {	/* CAPI_Cr removed */
#ifdef CAPI_CreateMemoryStream
	    return (IV)CAPI_CreateMemoryStream;
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
constant_CAPI_C(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'A':
	return constant_CAPI_CA(name, len, arg);
    case 'r':
	return constant_CAPI_Cr(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_THISA(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case 'F':
	if (strEQ(name + 10, "NDFUTURE")) {	/* CAPI_THISA removed */
#ifdef CAPI_THISANDFUTURE
	    return CAPI_THISANDFUTURE;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 10, "NDPRIOR")) {	/* CAPI_THISA removed */
#ifdef CAPI_THISANDPRIOR
	    return CAPI_THISANDPRIOR;
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
constant_CAPI_TH(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case 'A':
	if (!strnEQ(name + 7,"IS", 2))
	    break;
	return constant_CAPI_THISA(name, len, arg);
    case 'I':
	if (strEQ(name + 7, "ISINSTANCE")) {	/* CAPI_TH removed */
#ifdef CAPI_THISINSTANCE
	    return CAPI_THISINSTANCE;
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
constant_CAPI_TA(char *name, int len, int arg)
{
    if (7 + 9 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 9]) {
    case 'C':
	if (strEQ(name + 7, "SK_RANGE_COMPLETEDTIME")) {	/* CAPI_TA removed */
#ifdef CAPI_TASK_RANGE_COMPLETEDTIME
	    return CAPI_TASK_RANGE_COMPLETEDTIME;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 7, "SK_RANGE_DUETIME")) {	/* CAPI_TA removed */
#ifdef CAPI_TASK_RANGE_DUETIME
	    return CAPI_TASK_RANGE_DUETIME;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 7, "SK_RANGE_MASK")) {	/* CAPI_TA removed */
#ifdef CAPI_TASK_RANGE_MASK
	    return CAPI_TASK_RANGE_MASK;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 7, "SK_RANGE_STARTTIME")) {	/* CAPI_TA removed */
#ifdef CAPI_TASK_RANGE_STARTTIME
	    return CAPI_TASK_RANGE_STARTTIME;
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
constant_CAPI_T(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'A':
	return constant_CAPI_TA(name, len, arg);
    case 'H':
	return constant_CAPI_TH(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_CAPI_D(char *name, int len, int arg)
{
    if (6 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 6]) {
    case 'H':
	if (strEQ(name + 6, "estroyHandles")) {	/* CAPI_D removed */
#ifdef CAPI_DestroyHandles
	    return (IV)CAPI_DestroyHandles;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "estroyStreams")) {	/* CAPI_D removed */
#ifdef CAPI_DestroyStreams
	    return (IV)CAPI_DestroyStreams;
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
constant_C(char *name, int len, int arg)
{
    if (1 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 4]) {
    case 'A':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_A(name, len, arg);
    case 'C':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_C(name, len, arg);
    case 'D':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_D(name, len, arg);
    case 'F':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_F(name, len, arg);
    case 'G':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_G(name, len, arg);
    case 'H':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_H(name, len, arg);
    case 'L':
	if (strEQ(name + 1, "API_LOGOFF_STAY_CONNECTED")) {	/* C removed */
#ifdef CAPI_LOGOFF_STAY_CONNECTED
	    return CAPI_LOGOFF_STAY_CONNECTED;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_N(name, len, arg);
    case 'S':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_S(name, len, arg);
    case 'T':
	if (!strnEQ(name + 1,"API_", 4))
	    break;
	return constant_CAPI_T(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_FLAG_FETCH_V(char *name, int len, int arg)
{
    if (12 + 13 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 13]) {
    case '2':
	if (strEQ(name + 12, "CARD_VERSION_2_1")) {	/* FLAG_FETCH_V removed */
#ifdef FLAG_FETCH_VCARD_VERSION_2_1
	    return FLAG_FETCH_VCARD_VERSION_2_1;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "CARD_VERSION_3_0")) {	/* FLAG_FETCH_V removed */
#ifdef FLAG_FETCH_VCARD_VERSION_3_0
	    return FLAG_FETCH_VCARD_VERSION_3_0;
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
constant_FLAG_FETCH_EXCLUDE_A(char *name, int len, int arg)
{
    switch (name[20 + 0]) {
    case 'C':
	if (strEQ(name + 20, "CCEPTED")) {	/* FLAG_FETCH_EXCLUDE_A removed */
#ifdef FLAG_FETCH_EXCLUDE_ACCEPTED
	    return FLAG_FETCH_EXCLUDE_ACCEPTED;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 20, "PPOINTMENTS")) {	/* FLAG_FETCH_EXCLUDE_A removed */
#ifdef FLAG_FETCH_EXCLUDE_APPOINTMENTS
	    return FLAG_FETCH_EXCLUDE_APPOINTMENTS;
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
constant_FLAG_FETCH_EXCLUDE_DA(char *name, int len, int arg)
{
    switch (name[21 + 0]) {
    case 'I':
	if (strEQ(name + 21, "ILYNOTES")) {	/* FLAG_FETCH_EXCLUDE_DA removed */
#ifdef FLAG_FETCH_EXCLUDE_DAILYNOTES
	    return FLAG_FETCH_EXCLUDE_DAILYNOTES;
#else
	    goto not_there;
#endif
	}
    case 'Y':
	if (strEQ(name + 21, "YEVENTS")) {	/* FLAG_FETCH_EXCLUDE_DA removed */
#ifdef FLAG_FETCH_EXCLUDE_DAYEVENTS
	    return FLAG_FETCH_EXCLUDE_DAYEVENTS;
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
constant_FLAG_FETCH_EXCLUDE_D(char *name, int len, int arg)
{
    switch (name[20 + 0]) {
    case 'A':
	return constant_FLAG_FETCH_EXCLUDE_DA(name, len, arg);
    case 'E':
	if (strEQ(name + 20, "ECLINED")) {	/* FLAG_FETCH_EXCLUDE_D removed */
#ifdef FLAG_FETCH_EXCLUDE_DECLINED
	    return FLAG_FETCH_EXCLUDE_DECLINED;
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
constant_FLAG_FETCH_EXC(char *name, int len, int arg)
{
    if (14 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[14 + 5]) {
    case 'A':
	if (!strnEQ(name + 14,"LUDE_", 5))
	    break;
	return constant_FLAG_FETCH_EXCLUDE_A(name, len, arg);
    case 'D':
	if (!strnEQ(name + 14,"LUDE_", 5))
	    break;
	return constant_FLAG_FETCH_EXCLUDE_D(name, len, arg);
    case 'H':
	if (strEQ(name + 14, "LUDE_HOLIDAYS")) {	/* FLAG_FETCH_EXC removed */
#ifdef FLAG_FETCH_EXCLUDE_HOLIDAYS
	    return FLAG_FETCH_EXCLUDE_HOLIDAYS;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 14, "LUDE_NOTOWNER")) {	/* FLAG_FETCH_EXC removed */
#ifdef FLAG_FETCH_EXCLUDE_NOTOWNER
	    return FLAG_FETCH_EXCLUDE_NOTOWNER;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 14, "LUDE_UNCONFIRMED")) {	/* FLAG_FETCH_EXC removed */
#ifdef FLAG_FETCH_EXCLUDE_UNCONFIRMED
	    return FLAG_FETCH_EXCLUDE_UNCONFIRMED;
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
constant_FLAG_FETCH_E(char *name, int len, int arg)
{
    if (12 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case 'C':
	if (!strnEQ(name + 12,"X", 1))
	    break;
	return constant_FLAG_FETCH_EXC(name, len, arg);
    case 'P':
	if (strEQ(name + 12, "XPAND_RRULE")) {	/* FLAG_FETCH_E removed */
#ifdef FLAG_FETCH_EXPAND_RRULE
	    return FLAG_FETCH_EXPAND_RRULE;
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
constant_FLAG_F(char *name, int len, int arg)
{
    if (6 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 5]) {
    case 'A':
	if (strEQ(name + 6, "ETCH_AGENDA_ATTENDEE_ONLY")) {	/* FLAG_F removed */
#ifdef FLAG_FETCH_AGENDA_ATTENDEE_ONLY
	    return FLAG_FETCH_AGENDA_ATTENDEE_ONLY;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 6, "ETCH_COMBINED")) {	/* FLAG_F removed */
#ifdef FLAG_FETCH_COMBINED
	    return FLAG_FETCH_COMBINED;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 6, "ETCH_DO_NOT_EXPAND_RRULE")) {	/* FLAG_F removed */
#ifdef FLAG_FETCH_DO_NOT_EXPAND_RRULE
	    return FLAG_FETCH_DO_NOT_EXPAND_RRULE;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (!strnEQ(name + 6,"ETCH_", 5))
	    break;
	return constant_FLAG_FETCH_E(name, len, arg);
    case 'L':
	if (strEQ(name + 6, "ETCH_LOCALTIMES")) {	/* FLAG_F removed */
#ifdef FLAG_FETCH_LOCALTIMES
	    return FLAG_FETCH_LOCALTIMES;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (!strnEQ(name + 6,"ETCH_", 5))
	    break;
	return constant_FLAG_FETCH_V(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_FLAG_STORE_I(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case 'M':
	if (strEQ(name + 12, "MPORT")) {	/* FLAG_STORE_I removed */
#ifdef FLAG_STORE_IMPORT
	    return FLAG_STORE_IMPORT;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 12, "NVITE_SELF")) {	/* FLAG_STORE_I removed */
#ifdef FLAG_STORE_INVITE_SELF
	    return FLAG_STORE_INVITE_SELF;
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
constant_FLAG_STORE_REP(char *name, int len, int arg)
{
    if (14 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[14 + 1]) {
    case 'A':
	if (strEQ(name + 14, "LACE")) {	/* FLAG_STORE_REP removed */
#ifdef FLAG_STORE_REPLACE
	    return FLAG_STORE_REPLACE;
#else
	    goto not_there;
#endif
	}
    case 'Y':
	if (strEQ(name + 14, "LY")) {	/* FLAG_STORE_REP removed */
#ifdef FLAG_STORE_REPLY
	    return FLAG_STORE_REPLY;
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
constant_FLAG_STORE_R(char *name, int len, int arg)
{
    if (12 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case 'M':
	if (strEQ(name + 12, "EMOVE")) {	/* FLAG_STORE_R removed */
#ifdef FLAG_STORE_REMOVE
	    return FLAG_STORE_REMOVE;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (!strnEQ(name + 12,"E", 1))
	    break;
	return constant_FLAG_STORE_REP(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_FLAG_STO(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case 'C':
	if (strEQ(name + 8, "RE_CREATE")) {	/* FLAG_STO removed */
#ifdef FLAG_STORE_CREATE
	    return FLAG_STORE_CREATE;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (!strnEQ(name + 8,"RE_", 3))
	    break;
	return constant_FLAG_STORE_I(name, len, arg);
    case 'M':
	if (strEQ(name + 8, "RE_MODIFY")) {	/* FLAG_STO removed */
#ifdef FLAG_STORE_MODIFY
	    return FLAG_STORE_MODIFY;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (!strnEQ(name + 8,"RE_", 3))
	    break;
	return constant_FLAG_STORE_R(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_FLAG_S(char *name, int len, int arg)
{
    if (6 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'O':
	if (!strnEQ(name + 6,"T", 1))
	    break;
	return constant_FLAG_STO(name, len, arg);
    case 'R':
	if (strEQ(name + 6, "TREAM_NOT_MIME")) {	/* FLAG_S removed */
#ifdef FLAG_STREAM_NOT_MIME
	    return FLAG_STREAM_NOT_MIME;
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
constant_F(char *name, int len, int arg)
{
    if (1 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 4]) {
    case 'F':
	if (!strnEQ(name + 1,"LAG_", 4))
	    break;
	return constant_FLAG_F(name, len, arg);
    case 'N':
	if (strEQ(name + 1, "LAG_NONE")) {	/* F removed */
#ifdef FLAG_NONE
	    return FLAG_NONE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 1,"LAG_", 4))
	    break;
	return constant_FLAG_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_L(char *name, int len, int arg)
{
    if (1 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 3]) {
    case 'A':
	if (strEQ(name + 1, "OP_AND")) {	/* L removed */
#ifdef LOP_AND
	    return LOP_AND;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 1, "OP_OR")) {	/* L removed */
#ifdef LOP_OR
	    return LOP_OR;
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
constant(char *name, int len, int arg)
{
    errno = 0;
    switch (name[0 + 0]) {
    case 'C':
	return constant_C(name, len, arg);
    case 'F':
	return constant_F(name, len, arg);
    case 'H':
	if (strEQ(name + 0, "HANDLE_INITIALIZER")) {	/*  removed */
#ifdef HANDLE_INITIALIZER
	    return HANDLE_INITIALIZER;
#else
	    goto not_there;
#endif
	}
    case 'L':
	return constant_L(name, len, arg);
    case 'O':
	return constant_O(name, len, arg);
    case 'Q':
	if (strEQ(name + 0, "QUERY_INITIALIZER")) {	/*  removed */
#ifdef QUERY_INITIALIZER
	    return QUERY_INITIALIZER;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 0, "REQUEST_RESULT_INITIALIZER")) {	/*  removed */
#ifdef REQUEST_RESULT_INITIALIZER
	    return REQUEST_RESULT_INITIALIZER;
#else
	    goto not_there;
#endif
	}
    case 'S':
	return constant_S(name, len, arg);
    case 'U':
	if (strEQ(name + 0, "USE_OLD_NAMES")) {	/*  removed */
#ifdef USE_OLD_NAMES
	    return USE_OLD_NAMES;
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


MODULE = Oracle::CAPI		PACKAGE = Oracle::CAPI		PREFIX = CSDK_


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


CAPIStatus
CAPI_AuthenticateAsSysop(in_password, in_host, in_nodeId, in_flags, io_session)
	const char *	in_password
	const char *	in_host
	const char *	in_nodeId
	CAPIFlag	in_flags
	CAPISession *	io_session

CAPIStatus
CAPI_Capabilities(out_capabilities, in_host, in_flags)
	const char **	out_capabilities
	const char *	in_host
	CAPIFlag	in_flags

CAPIStatus
CAPI_Connect(in_host, in_flags, out_session)
	const char *	in_host
	CAPIFlag	in_flags
	CAPISession *	out_session

CAPIStatus
CAPI_DeleteEvent(in_session, in_handles, in_numHandles, io_status, in_flags, in_UID, in_RECURRENCEID, in_modifier)
	CAPISession	in_session
	CAPIHandle *	in_handles
	int	in_numHandles
	CAPIStatus *	io_status
	CAPIFlag	in_flags
	const char *	in_UID
	const char *	in_RECURRENCEID
	int	in_modifier

CAPIStatus
CAPI_FetchEventByID(in_session, in_handle, in_flags, in_UID, in_RECURRENCEID, in_modifier, in_requestProperties, in_numProperties, in_stream)
	CAPISession	in_session
	CAPIHandle	in_handle
	CAPIFlag	in_flags
	const char *	in_UID
	const char *	in_RECURRENCEID
	int	in_modifier
	const char **	in_requestProperties
	int	in_numProperties
	CAPIStream	in_stream

CAPIStatus
CAPI_FetchEventsByAlarmRange(in_session, in_handles, in_numHandles, io_status, in_flags, in_DTSTART, in_DTEND, in_requestProperties, in_numProperties, in_stream)
	CAPISession	in_session
	CAPIHandle *	in_handles
	int	in_numHandles
	CAPIStatus *	io_status
	CAPIFlag	in_flags
	const char *	in_DTSTART
	const char *	in_DTEND
	const char **	in_requestProperties
	int	in_numProperties
	CAPIStream	in_stream

CAPIStatus
CAPI_FetchEventsByRange(in_session, in_handles, in_numHandles, io_status, in_flags, in_DTSTART, in_DTEND, in_requestProperties, in_numProperties, in_stream)
	CAPISession	in_session
	CAPIHandle *	in_handles
	int	in_numHandles
	CAPIStatus *	io_status
	CAPIFlag	in_flags
	const char *	in_DTSTART
	const char *	in_DTEND
	const char **	in_requestProperties
	int	in_numProperties
	CAPIStream	in_stream

CAPIStatus
CAPI_GetLastStoredUID(in_session, out_UID, in_flags)
	CAPISession	in_session
	char const **	out_UID
	CAPIFlag	in_flags

CAPIStatus
CAPI_GetLastStoredUIDs(in_session, out_UIDs, out_numUIDs, in_flags)
	CAPISession	in_session
	char const * const **	out_UIDs
	unsigned long *	out_numUIDs
	CAPIFlag	in_flags

CAPIStatus
CAPI_Logoff(io_session, in_flags)
	CAPISession *	io_session
	CAPIFlag	in_flags

CAPIStatus
CAPI_Logon(in_user, in_password, in_host, in_flags, io_session)
	const char *	in_user
	const char *	in_password
	const char *	in_host
	CAPIFlag	in_flags
	CAPISession *	io_session

CAPIStatus
CAPI_StoreEvent(in_session, in_handles, in_numHandles, io_status, in_flags, in_stream)
	CAPISession	in_session
	CAPIHandle *	in_handles
	int	in_numHandles
	CAPIStatus *	io_status
	CAPIFlag	in_flags
	CAPIStream	in_stream

CAPIStatus
CSDK_AddConditionToQuery(in_query, in_condition, in_operator)
	CSDKQuery	in_query
	CSDKCondition *	in_condition
	CSDKOperator	in_operator

CAPISession
CSDK_Authenticate(in_host, in_user, in_password)
	char *	in_user
	char *	in_password
	char *	in_host
	INIT:
		CAPISession mySession = CSDK_SESSION_INITIALIZER;
		CAPIStatus myStatus = CSDK_CreateSession(CAPI_FLAG_NONE,&mySession);
	CODE:
		if (myStatus == CAPI_STAT_OK)
		{
			myStatus = CSDK_Connect(mySession, CAPI_FLAG_NONE, in_host);
			if (myStatus == CAPI_STAT_OK)
			{
				myStatus = CSDK_Authenticate(mySession,CAPI_FLAG_NONE,in_user,in_password);
				if (myStatus == CAPI_STAT_OK)
				{
					RETVAL = mySession;
				}
				else
				{
					XSRETURN_UNDEF;
				}
			}
			else
			{
				XSRETURN_UNDEF;
			}
		}
		else
		{
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

CAPISession
CSDK_SysopAuthUser(in_host, in_nodeid, in_syspass, in_user)
	char *	in_host
	char *	in_nodeid
	char *	in_syspass
	char *	in_user
	INIT:
		CAPISession mySession = CSDK_SESSION_INITIALIZER;
		CAPIStatus myStatus = CSDK_CreateSession(CAPI_FLAG_NONE,&mySession);
	CODE:
		if (myStatus == CAPI_STAT_OK)
		{
			myStatus = CSDK_ConnectAsSysop(mySession, CAPI_FLAG_NONE, in_host, in_nodeid, in_syspass);
			if (myStatus == CAPI_STAT_OK)
			{
				myStatus = CSDK_SetIdentity(mySession,in_user,CAPI_FLAG_NONE);
				if (myStatus == CAPI_STAT_OK)
				{
					RETVAL = mySession;
				}
				else
				{
					XSRETURN_UNDEF;
				}
			}
			else
			{
				XSRETURN_UNDEF;
			}
		}
		else
		{
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

CAPIStatus
CSDK_ConfigureACE(in_session, in_flags, in_authenticationMechanism, in_compressionMechanism, in_encryptionMechanism)
	CAPISession	in_session
	CAPIFlag	in_flags
	const char *	in_authenticationMechanism
	const char *	in_compressionMechanism
	const char *	in_encryptionMechanism

CAPIStatus
CSDK_Connect(in_session, in_flags, in_host)
	CAPISession	in_session
	CAPIFlag	in_flags
	const char *	in_host

CAPIStatus
CSDK_ConnectAsSysop(in_session, in_flags, in_host, in_nodeId, in_password)
	CAPISession	in_session
	CAPIFlag	in_flags
	const char *	in_host
	const char *	in_nodeId
	const char *	in_password

CAPIStatus
CSDK_CreateCallbackStream(in_session, out_stream, in_sendCallback, in_sendUserData, in_recvCallback, in_recvUserData, in_flags)
	CAPISession	in_session
	CAPIStream *	out_stream
	CAPICallback	in_sendCallback
	void *	in_sendUserData
	CAPICallback	in_recvCallback
	void *	in_recvUserData
	CAPIFlag	in_flags

CAPIStatus
CSDK_CreateFileStreamFromFilenames(in_session, out_stream, in_readFileName, in_readMode, in_writeFileName, in_writeMode, in_flags)
	CAPISession	in_session
	CAPIStream *	out_stream
	const char *	in_readFileName
	const char *	in_readMode
	const char *	in_writeFileName
	const char *	in_writeMode
	CAPIFlag	in_flags

CAPIStatus
CSDK_CreateMemoryStream(in_session, out_stream, in_readBuffer, out_writeBufferPtr, in_flags)
	CAPISession	in_session
	CAPIStream *	out_stream
	const char *	in_readBuffer
	const char **	out_writeBufferPtr
	CAPIFlag	in_flags

CAPIStatus
CSDK_CreateQuery(in_condition, out_query)
	CSDKCondition *	in_condition
	CSDKQuery *	out_query

CAPISession
CSDK_CreateSession()
	INIT:
		CAPISession mySession = CSDK_SESSION_INITIALIZER;
		CAPIStatus myStatus = CSDK_CreateSession(CAPI_FLAG_NONE,&mySession);
	CODE:
		if (myStatus == CAPI_STAT_OK)
		{
			RETVAL = mySession;
		}
		else
		{
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

CAPIStatus
CSDK_Deauthenticate(in_session, in_flags)
	CAPISession	in_session
	CAPIFlag	in_flags

CAPIStatus
CSDK_DeleteContacts(in_session, in_flags, in_UIDs, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIUIDSet	in_UIDs
	CSDKRequestResult *	out_requestResult

const char *
CSDK_DeleteContact(in_session, in_UID)
	CAPISession	in_session
	char *		in_UID
	INIT:
		CSDKRequestResult result = CSDK_REQUEST_RESULT_INITIALIZER;
		CAPIStatus 	stat = CAPI_STAT_OK;
		const char * 	uidSet[] = { in_UID, 0 };
	CODE:
		stat = CSDK_DeleteContacts(
                            in_session,
                            CSDK_FLAG_STREAM_NOT_MIME,
                            uidSet,
                            &result);

		if (result)
		{
		    CAPIStatus resultStatus = CAPI_STAT_OK;
		    stat = CSDK_GetFirstResult(
				    result,
				    0,
				    0,
				    &resultStatus);

                    CSDK_DestroyResult(&result);
		    if (!stat && resultStatus)
		    {
			stat = resultStatus;
		    }

		    if (stat)
		    {
			const char * statusString = 0;
			CSDK_GetStatusString(stat, &statusString);

			RETVAL = statusString;
		    }
		    else
		    {
			XSRETURN_UNDEF;
		    }
		}
		else if (stat)
		{
		   	const char * statusString = 0;
		    	CSDK_GetStatusString(stat, &statusString);

			RETVAL = statusString;
		}
		else
		{
			RETVAL = "No status returned??";
		}
	OUTPUT:
		RETVAL

CAPIStatus
CSDK_DeleteEvents(in_session, in_flags, in_UIDs, in_RECURRENCEID, in_modifier, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIUIDSet	in_UIDs
	const char *	in_RECURRENCEID
	int	in_modifier
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_DeleteTasks(in_session, in_flags, in_UIDs, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIUIDSet	in_UIDs
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_DestroyHandle(in_session, in_handle)
	CAPISession	in_session
	CAPIHandle *	in_handle

CAPIStatus
CSDK_DestroyMultipleHandles(in_session, in_handles, in_numHandles, in_flags)
	CAPISession	in_session
	CAPIHandle *	in_handles
	int	in_numHandles
	CAPIFlag	in_flags

CAPIStatus
CSDK_DestroyMultipleStreams(in_session, in_streams, in_numStreams, in_flags)
	CAPISession	in_session
	CAPIStream *	in_streams
	int	in_numStreams
	CAPIFlag	in_flags

CAPIStatus
CSDK_DestroyQuery(io_query)
	CSDKQuery *	io_query

CAPIStatus
CSDK_DestroyResult(io_requestResult)
	CSDKRequestResult *	io_requestResult

CAPIStatus
CSDK_DestroySession(io_session)
	CAPISession *	io_session

CAPIStatus
CSDK_DestroyPerlSession(io_session)
	CAPISession 	io_session
	CODE:
		RETVAL = CSDK_DestroySession(&io_session);
	OUTPUT:
		RETVAL

CAPIStatus
CSDK_DestroyStream(in_session, io_stream)
	CAPISession	in_session
	CAPIStream *	io_stream

CAPIStatus
CSDK_Disconnect(in_session, in_flags)
	CAPISession	in_session
	CAPIFlag	in_flags

CAPIStatus
CSDK_FetchContactsByQuery(in_session, in_flags, in_query, in_requestProperties, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CSDKQuery	in_query
	const char **	in_requestProperties
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

int
CSDK_FetchContacts(in_session, prop, op, value, result)
	CAPISession     in_session
	char *		prop
	int 		op
	char *		value
	const char *		result
	INIT:
		CSDKCondition cond = {prop,op,value};
		CSDKQuery myQuery = CSDK_QUERY_INITIALIZER;
		CAPIStatus myStatus = CSDK_CreateQuery(&cond,&myQuery);
		CSDKRequestResult reqres = CSDK_REQUEST_RESULT_INITIALIZER;
		CAPIStream myOutputStream = CSDK_STREAM_INITIALIZER;
		CAPIStatus status = CSDK_CreateMemoryStream(in_session,&myOutputStream,NULL,&result,CSDK_FLAG_NONE);
	CODE:
		if (status != CAPI_STAT_OK)
		{
			if (myStatus == CAPI_STAT_OK) CSDK_DestroyQuery(&myQuery);
			XSRETURN_UNDEF;
		}
		if (myStatus == CAPI_STAT_OK)
		{
			myStatus = CSDK_FetchContactsByQuery(in_session,CSDK_FLAG_STREAM_NOT_MIME,myQuery,NULL,myOutputStream,&reqres);
			CSDK_DestroyStream(in_session,&myOutputStream);
			CSDK_DestroyQuery(&myQuery);
			CSDK_DestroyResult(&reqres);
			if (myStatus != CAPI_STAT_OK) XSRETURN_UNDEF;
			RETVAL = 1;
		}
		else
		{
			CSDK_DestroyStream(in_session,&myOutputStream);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

int
CSDK_FetchContactsFile(in_session, prop, op, value,fname)
	CAPISession     in_session
	const char *		prop
	int 		op
	const char *		value
	const char *		fname
	INIT:
		CSDKCondition cond = {prop,op,value};
		CSDKQuery myQuery = CSDK_QUERY_INITIALIZER;
		CAPIStatus myStatus = CSDK_CreateQuery(&cond,&myQuery);
		CSDKRequestResult reqres = CSDK_REQUEST_RESULT_INITIALIZER;
		CAPIStream myOutputStream = CSDK_STREAM_INITIALIZER;
		CAPIStatus status = CSDK_CreateFileStreamFromFilenames(in_session,&myOutputStream,NULL,NULL,fname,"a",CSDK_FLAG_NONE);
	CODE:
		if (status != CAPI_STAT_OK)
		{
			if (myStatus == CAPI_STAT_OK) CSDK_DestroyQuery(&myQuery);
			XSRETURN_UNDEF;
		}
		if (myStatus == CAPI_STAT_OK)
		{
			myStatus = CSDK_FetchContactsByQuery(in_session,CSDK_FLAG_STREAM_NOT_MIME,myQuery,NULL,myOutputStream,&reqres);
			CSDK_DestroyStream(in_session,&myOutputStream);
			CSDK_DestroyQuery(&myQuery);
			CSDK_DestroyResult(&reqres);
			if (myStatus != CAPI_STAT_OK) XSRETURN_UNDEF;
			RETVAL = 1;
		}
		else
		{
			CSDK_DestroyStream(in_session,&myOutputStream);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

CAPIStatus
CSDK_FetchContactsByUID(in_session, in_flags, in_UIDs, in_requestProperties, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIUIDSet	in_UIDs
	const char **	in_requestProperties
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_FetchEventsByAlarmRange(in_session, in_flags, in_agendas, in_start, in_end, in_requestProperties, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIHandle *	in_agendas
	const char *	in_start
	const char *	in_end
	const char **	in_requestProperties
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_FetchEventsByRange(in_session, in_flags, in_agendas, in_start, in_end, in_requestProperties, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIHandle *	in_agendas
	const char *	in_start
	const char *	in_end
	const char **	in_requestProperties
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_FetchEventsByUID(in_session, in_flags, in_agenda, in_UIDs, in_RECURRENCEID, in_modifier, in_requestProperties, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIHandle	in_agenda
	CAPIUIDSet	in_UIDs
	const char *	in_RECURRENCEID
	int	in_modifier
	const char **	in_requestProperties
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_FetchTasksByAlarmRange(in_session, in_flags, in_handles, in_start, in_end, in_requestProperties, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIHandle *	in_handles
	const char *	in_start
	const char *	in_end
	const char **	in_requestProperties
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_FetchTasksByRange(in_session, in_flags, in_handles, in_start, in_end, in_requestProperties, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIHandle *	in_handles
	const char *	in_start
	const char *	in_end
	const char **	in_requestProperties
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_FetchTasksByUID(in_session, in_handle, in_flags, in_UIDs, in_requestProperties, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIHandle	in_handle
	CAPIFlag	in_flags
	CAPIUIDSet	in_UIDs
	const char **	in_requestProperties
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_GetCapabilities(in_session, in_capabilityID, in_flags, out_value)
	CAPISession	in_session
	CAPICapabilityID	in_capabilityID
	CAPIFlag	in_flags
	const char **	out_value

CAPIStatus
CSDK_GetFirstFailure(in_requestResult, out_user, out_uid, out_status)
	CSDKRequestResult	in_requestResult
	CAPIHandle *	out_user
	const char **	out_uid
	CAPIStatus *	out_status

CAPIStatus
CSDK_GetFirstParseError(in_requestResult, out_status, out_errorBuffer, out_errorLocation, out_message)
	CSDKRequestResult	in_requestResult
	CAPIStatus *	out_status
	const char **	out_errorBuffer
	const char **	out_errorLocation
	const char **	out_message

CAPIStatus
CSDK_GetFirstResult(in_requestResult, out_user, out_uid, out_status)
	CSDKRequestResult	in_requestResult
	CAPIHandle *	out_user
	const char **	out_uid
	CAPIStatus *	out_status

CAPIStatus
CSDK_GetHandle(in_session, in_user, in_flags, out_handle)
	CAPISession	in_session
	const char *	in_user
	CAPIFlag	in_flags
	CAPIHandle *	out_handle

CAPIStatus
CSDK_GetHandleInfo(in_session, in_handle, in_flags, out_info)
	CAPISession	in_session
	CAPIHandle	in_handle
	CAPIFlag	in_flags
	const char **	out_info

CAPIStatus
CSDK_GetNextFailure(in_requestResult, out_user, out_uid, out_status)
	CSDKRequestResult	in_requestResult
	CAPIHandle *	out_user
	const char **	out_uid
	CAPIStatus *	out_status

CAPIStatus
CSDK_GetNextParseError(in_requestResult, out_status, out_errorBuffer, out_errorLocation, out_message)
	CSDKRequestResult	in_requestResult
	CAPIStatus *	out_status
	const char **	out_errorBuffer
	const char **	out_errorLocation
	const char **	out_message

CAPIStatus
CSDK_GetNextResult(in_requestResult, out_user, out_uid, out_status)
	CSDKRequestResult	in_requestResult
	CAPIHandle *	out_user
	const char **	out_uid
	CAPIStatus *	out_status

void
CSDK_GetStatusLevels(in_status, out_field1, out_field2, out_field3, out_field4, out_field5)
	CAPIStatus	in_status
	unsigned long *	out_field1
	unsigned long *	out_field2
	unsigned long *	out_field3
	unsigned long *	out_field4
	unsigned long *	out_field5

char *
CSDK_GetStatusString(in_status)
	CAPIStatus	in_status
	INIT:
		const char **rvbuf;
		char rvvbuf[2048];

	CODE:
		CSDK_GetStatusString(in_status,rvbuf);
		strncpy(rvvbuf,*rvbuf,2048);
		RETVAL = rvvbuf;
	OUTPUT:
		RETVAL

CAPIStatus
CSDK_SetConfigFile(in_configFileName, in_logFileName)
	const char *	in_configFileName
	const char *	in_logFileName

const char *
CSDK_ReconnectAuthUser(in_session, in_host, in_nodeid, in_syspass, in_user)
	CAPISession	in_session
	const char *	in_host
	const char *	in_nodeid
	const char *	in_syspass
	const char *	in_user
	INIT:
		CAPIStatus stat = CAPI_STAT_OK;
		const char * statusString = 0;
	CODE:
		stat = CSDK_Deauthenticate(in_session, CSDK_FLAG_NONE);
		if (stat)
		{
			CSDK_GetStatusString(stat, &statusString);
			XSRETURN_PV(statusString);
		}
		stat = CSDK_ConnectAsSysop(in_session, CAPI_FLAG_NONE, in_host, in_nodeid, in_syspass);
		if (stat == CAPI_STAT_OK)
		{
			stat = CSDK_SetIdentity(in_session,in_user,CAPI_FLAG_NONE);
			if (stat == CAPI_STAT_OK)
			{
				XSRETURN_UNDEF;
			}
			else
			{
				CSDK_GetStatusString(stat, &statusString);
				XSRETURN_PV(statusString);
			}
		}
		else
		{
			CSDK_GetStatusString(stat, &statusString);
			XSRETURN_PV(statusString);
		}
	OUTPUT:
		RETVAL

const char *
CSDK_ChangeIdentity(in_session, in_user)
	CAPISession	in_session
	const char *	in_user
	INIT:
		CAPIStatus stat = CAPI_STAT_OK;
		const char * statusString = 0;
	CODE:
		stat = CSDK_SetIdentity(in_session,in_user,CAPI_FLAG_NONE);
		if (stat == CAPI_STAT_OK)
		{
			XSRETURN_UNDEF;
		}
		else
		{
			CSDK_GetStatusString(stat, &statusString);
			XSRETURN_PV(statusString);
		}
	OUTPUT:
		RETVAL

CAPIStatus
CSDK_SetIdentity(in_session, in_user, in_flags)
	CAPISession	in_session
	const char *	in_user
	CAPIFlag	in_flags

CAPIStatus
CSDK_StoreContacts(in_session, in_flags, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

const char *
CSDK_StoreContactUpdate(in_session, in_vcard)
	CAPISession	in_session
	const char *	in_vcard
	INIT:
		CAPIStatus stat = CAPI_STAT_OK;
		CAPIFlag   mode = CSDK_FLAG_STORE_MODIFY | CSDK_FLAG_STREAM_NOT_MIME;
		CAPIStream memStream = CSDK_STREAM_INITIALIZER;
		const char * memBuffer = 0;
		CSDKRequestResult reqres = CSDK_REQUEST_RESULT_INITIALIZER;
		const char * statusString = 0;
	CODE:
/*
 * Updates a contact already on the server with the new vCard. The vCard with that UID is then updated: all properties contained 
 * in the vCard on the server that are present in the passed-in vCard are modified to contain the property values of the passed-in 
 * vCard. Also, all properties that exist in the passed-in vCard that don't exist on the server vCard are added to the server vCard. 
 * All other properties not present in the passed-in vCard that exist on the server are ignored.
 * 
 * Return false if all went well, otherwise return an error string

		char outVCard[10000];

		strcpy(outVCard, "MIME-Version: 1.0\015\012Content-Type: multipart/mixed;\015\012boundary=\"------------CA94974D4D8713DE5B12E6CD\"\015\012\015\012This is a multi-part message in MIME format.\015\012--------------CA94974D4D8713DE5B12E6CD\015\012Content-Type: text/x-vcard; charset=UTF-8;\015\012name=\"example.vcf\"\015\012Content-Disposition: attachment;\015\012filename=\"example.vcf\"\015\012Content-Transfer-Encoding: quoted-printable\015\012\015\012BEGIN:VCARD\015\012UID:ORACLE:CALSERV:CONTACT/AAAAAQAAAVcAyAAACpsAAABsAAQAAAAA\015\012URL;TYPE=WORK:http://www.helloCHANGED.com/tar.gz\015\012REV:20040212T000004Z\015\012N;ENCODING=QUOTED-PRINTABLE:Xarby;Zerrence;Trent;Miss;III\015\012FN;ENCODING=QUOTED-PRINTABLE:Xarby, Zerrence Trent\015\012VERSION:3.0\015\012END:VCARD\015\012\015\012--------------CA94974D4D8713DE5B12E6CD--\015\012\015\012");
 */

		stat = CSDK_CreateMemoryStream(in_session,
                                 &memStream,
                                 in_vcard,
                                 NULL,
                                 CAPI_FLAG_NONE);

		if (stat != CAPI_STAT_OK) XSRETURN_PV("Unable to create memory stream");

		stat = CSDK_StoreContacts(in_session,
                          mode,
                          memStream,
                          &reqres);
		CSDK_DestroyStream(in_session,&memStream);

                if (stat)
                {
                            CSDK_GetStatusString(stat, &statusString);
                            if (reqres) CSDK_DestroyResult(&reqres);
                            RETVAL = statusString;
                }
                else if (reqres)
                {
			const char * uid;
			CAPIStatus   resultStat;

			stat = CSDK_GetFirstResult(
					    reqres,
					    0,
					    &uid,
					    &resultStat);

			if (!stat && resultStat)
			{
			    stat = resultStat;
			}

			if (stat)
			{
			    CSDK_GetStatusString(stat, &statusString);
			    RETVAL = statusString;
			}
			else
			{
                            if (reqres) CSDK_DestroyResult(&reqres);
			    XSRETURN_UNDEF;
			}
		}
		else
		{
			RETVAL = "No status returned??";
		}
		if (reqres) CSDK_DestroyResult(&reqres);
	OUTPUT:
		RETVAL

const char *
CSDK_CreateContact(in_session, in_vcard)
        CAPISession     in_session
        const char *    in_vcard
        INIT:
                CAPIStatus stat = CAPI_STAT_OK;
                CAPIFlag   mode = CSDK_FLAG_STORE_CREATE | CSDK_FLAG_STREAM_NOT_MIME;
                CAPIStream memStream = CSDK_STREAM_INITIALIZER;
                const char * memBuffer = 0;
                CSDKRequestResult reqres = CSDK_REQUEST_RESULT_INITIALIZER;
                const char * statusString = 0;
        CODE:
                stat = CSDK_CreateMemoryStream(in_session,
                                 &memStream,
                                 in_vcard,
                                 NULL,
                                 CAPI_FLAG_NONE);

                if (stat != CAPI_STAT_OK) XSRETURN_PV("Unable to create memory stream");

                stat = CSDK_StoreContacts(in_session,
                          mode,
                          memStream,
                          &reqres);
                CSDK_DestroyStream(in_session,&memStream);

                if (stat)
                {
                            CSDK_GetStatusString(stat, &statusString);
                            if (reqres) CSDK_DestroyResult(&reqres);
                            RETVAL = statusString;
                }
                else if (reqres)
                {
                        const char * uid;
                        CAPIStatus   resultStat;

                        stat = CSDK_GetFirstResult(
                                            reqres,
                                            0,
                                            &uid,
                                            &resultStat);

                        if (!stat && resultStat)
                        {
                            stat = resultStat;
                        }

                        if (stat)
                        {
                            CSDK_GetStatusString(stat, &statusString);
                            RETVAL = statusString;
                        }
                        else
                        {
                            if (reqres) CSDK_DestroyResult(&reqres);
                            XSRETURN_UNDEF;
                        }
                }
                else
                {
                        RETVAL = "No status returned??";
                }
                if (reqres) CSDK_DestroyResult(&reqres);
        OUTPUT:
                RETVAL

CAPIStatus
CSDK_StoreEvents(in_session, in_flags, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

CAPIStatus
CSDK_StoreTasks(in_session, in_flags, in_stream, out_requestResult)
	CAPISession	in_session
	CAPIFlag	in_flags
	CAPIStream	in_stream
	CSDKRequestResult *	out_requestResult

MODULE = Oracle::CAPI		PACKAGE = CSDKCondition		PREFIX = CSDK_

CSDKCondition *
_to_ptr(THIS)
	CSDKCondition THIS = NO_INIT
    PROTOTYPE: $
    CODE:
	if (sv_derived_from(ST(0), "CSDKCondition")) {
	    STRLEN len;
	    char *s = SvPV((SV*)SvRV(ST(0)), len);
	    if (len != sizeof(THIS))
		croak("Size %d of packed data != expected %d",
			len, sizeof(THIS));
	    RETVAL = (CSDKCondition *)s;
	}   
	else
	    croak("THIS is not of type CSDKCondition");
    OUTPUT:
	RETVAL

CSDKCondition
new(CLASS)
	char *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
	Zero((void*)&RETVAL, sizeof(RETVAL), char);
    OUTPUT:
	RETVAL

MODULE = Oracle::CAPI		PACKAGE = CSDKConditionPtr		PREFIX = CSDK_

CSDKOperator
op(THIS, __value = NO_INIT)
	CSDKCondition * THIS
	CSDKOperator __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->op = __value;
	RETVAL = THIS->op;
    OUTPUT:
	RETVAL

