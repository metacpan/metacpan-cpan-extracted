#ifndef PIGFUNC_QT_H
#define PIGFUNC_QT_H

/*
 * Support functions for PerlQt
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigfunc.h"

PIG_DECLARE_VARIABLE(class QDataStream *, pig_dstreamptr)
#define pig_dstreamptr PIG_VARIABLE(pig_dstreamptr)

#define pig_serialize(object) pig_munge_qdatastream(operator<<(*pig_dstreamptr, *object))
#define pig_deserialize(object, data) pig_unmunge_qdatastream(data); operator>>(*pig_dstreamptr, *object)

PIG_DECLARE_FUNC_1(const char *, pig_munge_qdatastream, class QDataStream &)
PIG_DECLARE_VOID_FUNC_1(pig_unmunge_qdatastream, const char *)

PIG_IMPORT_TABLE(pigfunc_qt)
    PIG_IMPORT_FUNC(pig_munge_qdatastream)
    PIG_IMPORT_FUNC(pig_unmunge_qdatastream)
    PIG_IMPORT_VARIABLE(pig_dstreamptr)
PIG_IMPORT_ENDTABLE

#endif  // PIGFUNC_QT_H
