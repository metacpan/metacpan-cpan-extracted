// -*- mode: C++; c-file-style: "cc-mode" -*-
//********************************************************************
//
// THIS MODULE IS PUBLICLY LICENSED
//
// Copyright 2001-2014 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the GNU
// Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
//
// This is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
//********************************************************************
///
/// \file
/// \brief SystemPerl: Overall header file for all SystemPerl programs
///
/// AUTHOR:  Wilson Snyder
///
/// This file should be #included at the top of all SystemPerl
/// programs/modules that require any SystemC functions, instead of
/// systemc.h.
///
//********************************************************************

#ifndef _SYSTEMPERL_H_
#define _SYSTEMPERL_H_

#ifdef _VERILATED_H_
# error "You must include systemperl.h before verilated.h"
#endif

/* Necessary includes */
#include "SpCommon.h"

#include <sstream>	// For AUTOENUM
using namespace std;
#ifdef SYSTEMC_LESSER	// Allow users to manually make a lighter weight systemc include file
# include <systemc_lesser.h>
#else
# include <systemc.h>
#endif
#include <cstdarg>      // ... vaargs

//********************************************************************
// Switches

#ifndef SYSTEMPERL
# define SYSTEMPERL 1
#endif

//********************************************************************
// Version compatibility

#if (SYSTEMC_VERSION>=20050714) // SystemC 2.1.v1
typedef std::string sp_string;	///< sc_string or std::string compatible across SC versions
#else
typedef sc_string sp_string;	///< sc_string or std::string compatible across SC versions
#endif

//********************************************************************
// Macros

/// Like SC_MODULE but not managed as a module (for coverage, etc)
#define SP_CLASS(name) class name

/// Allows constructor to be in implementation rather than the header
#define SP_CTOR_IMP(name) name::name(sc_module_name)

/// Declaration of cell for interface
#define SP_CELL_DECL(type,instname) type *instname

/// Instantiation of a cell in CTOR
#define SP_CELL(instname,type) (instname = new type (# instname))

/// Instantiation of a cell in CTOR
// Allocate using a formatted name
#define SP_CELL_FORM(instname,type,format...) \
	(instname = new type (sp_cell_sprintf(format)))

/// Connection of a pin to a SC_CELL
#define SP_PIN(instname,port,net) (instname->port(net))

// Tracing types
#define SP_TRACED	// Just a NOP; it simply marks a declaration
#ifndef VL_SIG
# define VL_SIG8(name, msb,lsb)		uint8_t  name
# define VL_SIG16(name, msb,lsb)	uint16_t  name
# define VL_SIG64(name, msb,lsb)	uint64_t  name
# define VL_SIG(name, msb,lsb)		uint32_t name
# define VL_SIGW(name, msb,lsb, words)	uint32_t name[words]
# define VL_IN8(name, msb,lsb)		uint8_t  name
# define VL_IN16(name, msb,lsb)		uint16_t  name
# define VL_IN64(name, msb,lsb)		uint64_t  name
# define VL_IN(name, msb,lsb)		uint32_t name
# define VL_INW(name, msb,lsb, words)	uint32_t name[words]
# define VL_INOUT8(name, msb,lsb)	uint8_t  name
# define VL_INOUT16(name, msb,lsb)	uint16_t  name
# define VL_INOUT64(name, msb,lsb)	uint64_t  name
# define VL_INOUT(name, msb,lsb)	uint32_t name
# define VL_INOUTW(name, msb,lsb, words) uint32_t name[words]
# define VL_OUT8(name, msb,lsb)		uint8_t  name
# define VL_OUT16(name, msb,lsb)	uint16_t  name
# define VL_OUT64(name, msb,lsb)	uint64_t  name
# define VL_OUT(name, msb,lsb)		uint32_t name
# define VL_OUTW(name, msb,lsb, words)	uint32_t name[words]
# define VL_PIN_NOP(instname,pin,port)
# define VL_CELL(instname,type)
# define VL_MODULE(modname)		struct modname : public VerilatedModule
# define VL_CTOR(modname)		modname(const char* __VCname="")
# define VL_CTOR_IMP(modname)		modname::modname(const char* __VCname) : VerilatedModule(__VCname)
#endif

//********************************************************************
// Functions

// We'll ask systemC to have a sc_string creator to avoid this:
// Note there is a mem leak here.  As only used for instance names, we'll live.
inline const char *sp_cell_sprintf(const char *fmt...) {
    char* buf = new char[strlen(fmt) + 20];
    va_list ap; va_start(ap,fmt); vsprintf(buf,fmt,ap); va_end(ap);
    return(buf);
}

//********************************************************************
// Classes so we can sometimes avoid header inclusion

class SpTraceVcd;
class SpTraceVcdCFile;
class SpTraceFile;

//********************************************************************
// sp_log.h has whole thing... This one function may be used everywhere

#ifndef UTIL_ATTR_PRINTF
# ifdef __GNUC__
#  define UTIL_ATTR_PRINTF(fmtArgNum) __attribute__ ((format (printf, fmtArgNum, fmtArgNum+1)))
# else
#  define UTIL_ATTR_PRINTF(fmtArgNum)
# endif
#endif

extern "C" {
    /// Print to cout, but with C style arguments
    extern void sp_log_printf(const char *format, ...) UTIL_ATTR_PRINTF(1);
}

//********************************************************************
// SystemC Automatics

#define SP_AUTO_CTOR
#define SP_AUTO_METHOD(func, sensitive_expr)
#define SP_MODULE_CONTINUED(modname)
#define SP_TEMPLATE(cellregexp, pinregexp, netregexp...)

// Multiple flavors as all compilers don't support variable define arguments
#define SP_AUTO_COVER()
#define SP_AUTO_COVER1(type)
#define SP_AUTO_COVER3(type,file,line)
#define SP_AUTO_COVER4(type,file,line,cmt)
/// Coverage, with the comment specified
#define SP_AUTO_COVER_CMT(cmt)
/// Coverage, with the comment specified.  Only enable the point if expression
/// is true; note this must be evaluatable in the constructor also.
#define SP_AUTO_COVER_CMT_IF(cmt,enablestmt)

/// Coverage group declaration
#define SP_COVERGROUP(...)

/// Coverage group sample
#define SP_COVER_SAMPLE(name)

// Below inserted by preprocessor, not for internal use
#define SP_AUTO_COVERinc(id,type,file,line,cmt) {SP_IF_COVER(++(this->_sp_coverage[(id)]));}

//********************************************************************

#endif // guard
