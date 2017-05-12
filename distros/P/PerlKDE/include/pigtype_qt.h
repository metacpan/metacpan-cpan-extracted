#ifndef PIGTYPE_QT_H
#define PIGTYPE_QT_H

/*
 * Pig support for types required by PerlQt
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigfunc.h"
#include "pigtype.h"

PIG_DECLARE_TYPE(pig_type_argc)
PIG_DECLARE_TYPE(pig_type_argv)

PIG_DECLARE_TYPE(pig_type_serial)

PIG_DECLARE_TYPE(pig_type_sender)
PIG_DECLARE_TYPE(pig_type_signal)
PIG_DECLARE_TYPE(pig_type_receiver)
PIG_DECLARE_TYPE(pig_type_unreceiver)
PIG_DECLARE_TYPE(pig_type_member)

PIG_DECLARE_TYPE(pig_type_qt_xpm)
PIG_DECLARE_TYPE(pig_type_qt_bits)
PIG_DECLARE_TYPE(pig_type_qt_bitslen)
PIG_DECLARE_TYPE(pig_type_qt_ubits)
PIG_DECLARE_TYPE(pig_type_qt_ubitsarray)
PIG_DECLARE_TYPE(pig_type_qt_uintarray)
PIG_DECLARE_TYPE(pig_type_qt_pointarrayitems)

PIG_DECLARE_TYPE(pig_type_qt_HVorientation)
PIG_DECLARE_TYPE(pig_type_qt_VHorientation)

PIG_DECLARE_TYPE(pig_type_qt_QString)
PIG_DECLARE_TYPE(pig_type_qt_QString_ptr)
PIG_DECLARE_TYPE(pig_type_qt_QString_ref)
PIG_DECLARE_TYPE(pig_type_qt_const_QString_ptr)
PIG_DECLARE_TYPE(pig_type_qt_const_QString_ref)

#if QT_VERSION > 200
PIG_DECLARE_TYPE(pig_type_qt_QCString)
PIG_DECLARE_TYPE(pig_type_qt_QCString_ptr)
PIG_DECLARE_TYPE(pig_type_qt_QCString_ref)
PIG_DECLARE_TYPE(pig_type_qt_const_QCString_ptr)
PIG_DECLARE_TYPE(pig_type_qt_const_QCString_ref)
#endif

PIG_DECLARE_TYPE(pig_type_qt_QByteArray_ptr)
PIG_DECLARE_TYPE(pig_type_qt_QArray_QRect_ptr)

PIG_DECLARE_TYPE(pig_type_qt_QFileInfo_ptr)
PIG_DECLARE_TYPE(pig_type_qt_QFileInfoList_ptr)

#if QT_VERSION > 200
PIG_DECLARE_TYPE(pig_type_qt_QStringList_ptr)
#endif

PIG_DECLARE_TYPE(pig_type_qt_QStrList_ptr)
PIG_DECLARE_TYPE(pig_type_qt_leak_QStrList_ptr)
PIG_DECLARE_TYPE(pig_type_qt_QTabList_ptr)
PIG_DECLARE_TYPE(pig_type_qt_QObjectList_ptr)
PIG_DECLARE_TYPE(pig_type_qt_QWidgetList_ptr)

PIGTYPE_ARGUMENT2(pig_type_argc, int &, int)
PIGTYPE_ARGUMENT(pig_type_argv, char **)

PIGTYPE_ARGUMENT2(pig_type_sender, class QObject *, int)
PIGTYPE_DEFARGUMENT2(pig_type_sender, class QObject *, int)
PIGTYPE_ARGUMENT2(pig_type_signal, const char *, int)
PIGTYPE_DEFARGUMENT2(pig_type_signal, const char *, int)
PIGTYPE_PUSH(pig_type_signal, const char *)
PIGTYPE_ARGUMENT2(pig_type_receiver, class QObject *, int)
PIGTYPE_DEFARGUMENT2(pig_type_receiver, class QObject *, int)
PIGTYPE_PUSH(pig_type_receiver, const class QObject *)
PIGTYPE_ARGUMENT2(pig_type_unreceiver, class QObject *, int)
PIGTYPE_DEFARGUMENT2(pig_type_unreceiver, class QObject *, int)
PIGTYPE_ARGUMENT2(pig_type_member, const char *, int)
PIGTYPE_DEFARGUMENT2(pig_type_member, const char *, int)
PIGTYPE_PUSH(pig_type_member, const char *)

PIGTYPE_ARGUMENT(pig_type_serial, const char *)
PIGTYPE_RETURN(pig_type_serial, const char *)

PIGTYPE_ARGUMENT(pig_type_qt_xpm, const char **)
PIGTYPE_ARGUMENT(pig_type_qt_bits, char *)
PIGTYPE_ARGUMENT2(pig_type_qt_bitslen, int, int)
PIGTYPE_RETURN(pig_type_qt_ubits, unsigned char *)
PIGTYPE_RETURN(pig_type_qt_uintarray, unsigned int *)
PIGTYPE_ARGUMENT2(pig_type_qt_pointarrayitems, int, int)

PIGTYPE_ALL(pig_type_qt_HVorientation, int)
PIGTYPE_ALL(pig_type_qt_VHorientation, int)

PIGTYPE_CONST_ALL(pig_type_qt_QString, class QString &)
PIGTYPE_CONST_ALL(pig_type_qt_QString_ptr, class QString *)
PIGTYPE_CONST_ALL(pig_type_qt_QString_ref, class QString &)
PIGTYPE_ALL(pig_type_qt_const_QString_ptr, const class QString *)
PIGTYPE_ALL(pig_type_qt_const_QString_ref, const class QString &)

#if QT_VERSION > 200
PIGTYPE_CONST_ALL(pig_type_qt_QCString, class QCString &)
PIGTYPE_CONST_ALL(pig_type_qt_QCString_ptr, class QCString *)
PIGTYPE_CONST_ALL(pig_type_qt_QCString_ref, class QCString &)
PIGTYPE_ALL(pig_type_qt_const_QCString_ptr, const class QCString *)
PIGTYPE_ALL(pig_type_qt_const_QCString_ref, const class QCString &)
#endif

PIGTYPE_ARGUMENT(pig_type_qt_QByteArray_ptr, const void *)
PIGTYPE_RETURN(pig_type_qt_QByteArray_ptr, const void *)
PIGTYPE_PUSH(pig_type_qt_QByteArray_ptr, const void *)
PIGTYPE_POP(pig_type_qt_QByteArray_ptr, void *)
PIGTYPE_RETURN(pig_type_qt_QArray_QRect_ptr, const void *)

PIGTYPE_ARGUMENT(pig_type_qt_QFileInfo_ptr, class QFileInfo *)
PIGTYPE_PUSH(pig_type_qt_QFileInfo_ptr, const class QFileInfo *)
PIGTYPE_RETURN(pig_type_qt_QFileInfoList_ptr, const void *)

#if QT_VERSION > 200
PIGTYPE_ARGUMENT(pig_type_qt_QStringList_ptr, void *)
PIGTYPE_RETURN(pig_type_qt_QStringList_ptr, const void *)
PIGTYPE_PUSH(pig_type_qt_QStringList_ptr, const void *)
#endif

PIGTYPE_ARGUMENT(pig_type_qt_QStrList_ptr, void *)
PIGTYPE_RETURN(pig_type_qt_QStrList_ptr, const void *)
PIGTYPE_PUSH(pig_type_qt_QStrList_ptr, const void *)
PIGTYPE_POP(pig_type_qt_QStrList_ptr, void *)

PIGTYPE_ARGUMENT(pig_type_qt_leak_QStrList_ptr, void *)

PIGTYPE_RETURN(pig_type_qt_QTabList_ptr, const void *)
PIGTYPE_RETURN(pig_type_qt_QObjectList_ptr, const void *)
PIGTYPE_RETURN(pig_type_qt_QWidgetList_ptr, const void *)

PIG_DECLARE_FUNC_1(const unsigned char *, pig_type_qt_ubits_argument_qsize, int)
PIG_DECLARE_FUNC_2(const unsigned char *, pig_type_qt_ubits_argument_int_int, int, int)
PIG_DECLARE_VOID_FUNC_2(pig_type_qt_bits_return, const char *, unsigned int)
PIG_DECLARE_VOID_FUNC_4(pig_type_qt_ubitsarray_return, unsigned char **, int, int, int)

inline const unsigned char *pig_type_qt_ubits_argument(int pig0) {
    return pig_type_qt_ubits_argument_qsize(pig0);
}
inline const unsigned char *pig_type_qt_ubits_argument(int pig0, int pig1) {
    return pig_type_qt_ubits_argument_int_int(pig0, pig1);
}

PIG_IMPORT_TABLE(pigtype_qt)
    PIG_IMPORT_TYPE(pig_type_argc, "Qt argc")
    PIG_IMPORT_TYPE(pig_type_argv, "Qt argv")
    PIG_IMPORT_TYPE(pig_type_serial, "Qt serial")
    PIG_IMPORT_TYPE(pig_type_sender, "Qt sender")
    PIG_IMPORT_TYPE(pig_type_signal, "Qt signal")
    PIG_IMPORT_TYPE(pig_type_receiver, "Qt receiver")
    PIG_IMPORT_TYPE(pig_type_unreceiver, "Qt unreceiver")
    PIG_IMPORT_TYPE(pig_type_member, "Qt member")
    PIG_IMPORT_TYPE(pig_type_qt_xpm, "Qt xpm")
    PIG_IMPORT_TYPE(pig_type_qt_bits, "Qt bits")
    PIG_IMPORT_TYPE(pig_type_qt_bitslen, "Qt sizeof(bits)")
    PIG_IMPORT_TYPE(pig_type_qt_ubits, "Qt ubits")
    PIG_IMPORT_TYPE(pig_type_qt_ubitsarray, "Qt ubits[]")
    PIG_IMPORT_TYPE(pig_type_qt_uintarray, "Qt uint[]")
    PIG_IMPORT_TYPE(pig_type_qt_pointarrayitems, "Qt sizeof(point[])")
    PIG_IMPORT_TYPE(pig_type_qt_HVorientation, "Qt HVorientation")
    PIG_IMPORT_TYPE(pig_type_qt_VHorientation, "Qt VHorientation")
    PIG_IMPORT_TYPE(pig_type_qt_QString, "Qt QString")
    PIG_IMPORT_TYPE(pig_type_qt_QString_ptr, "Qt QString*")
    PIG_IMPORT_TYPE(pig_type_qt_QString_ref, "Qt QString&")
    PIG_IMPORT_TYPE(pig_type_qt_const_QString_ptr, "Qt const QString*")
    PIG_IMPORT_TYPE(pig_type_qt_const_QString_ref, "Qt const QString&")
#if QT_VERSION > 200
    PIG_IMPORT_TYPE(pig_type_qt_QCString, "Qt QCString")
    PIG_IMPORT_TYPE(pig_type_qt_QCString_ptr, "Qt QCString*")
    PIG_IMPORT_TYPE(pig_type_qt_QCString_ref, "Qt QCString&")
    PIG_IMPORT_TYPE(pig_type_qt_const_QCString_ptr, "Qt const QCString*")
    PIG_IMPORT_TYPE(pig_type_qt_const_QCString_ref, "Qt const QCString&")
#endif
    PIG_IMPORT_TYPE(pig_type_qt_QByteArray_ptr, "Qt QByteArray*")
    PIG_IMPORT_TYPE(pig_type_qt_QArray_QRect_ptr, "Qt QArray<QRect>*")
    PIG_IMPORT_TYPE(pig_type_qt_QFileInfo_ptr, "Qt QFileInfo*")
    PIG_IMPORT_TYPE(pig_type_qt_QFileInfoList_ptr, "Qt QFileInfoList*")
#if QT_VERSION > 200
    PIG_IMPORT_TYPE(pig_type_qt_QStringList_ptr, "Qt QStringList*")
#endif
    PIG_IMPORT_TYPE(pig_type_qt_QStrList_ptr, "Qt QStrList*")
    PIG_IMPORT_TYPE(pig_type_qt_leak_QStrList_ptr, "Qt new QStrList*")
    PIG_IMPORT_TYPE(pig_type_qt_QTabList_ptr, "Qt QTabList*")
    PIG_IMPORT_TYPE(pig_type_qt_QObjectList_ptr, "Qt QObjectList*")
    PIG_IMPORT_TYPE(pig_type_qt_QWidgetList_ptr, "Qt QWidgetList*")

    PIG_IMPORT_FUNC(pig_type_qt_ubits_argument_qsize)
    PIG_IMPORT_FUNC(pig_type_qt_ubits_argument_int_int)
    PIG_IMPORT_FUNC(pig_type_qt_bits_return)
    PIG_IMPORT_FUNC(pig_type_qt_ubitsarray_return)
PIG_IMPORT_ENDTABLE

#endif  // PIGTYPE_QT_H
