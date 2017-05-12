// -*- mode: C++; c-file-style: "cc-mode" -*-
//=============================================================================
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
//=============================================================================
///
/// \file
/// \brief SystemPerl common simple utilities, not requiring SystemC
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#ifndef _SPCOMMON_H_
#define _SPCOMMON_H_ 1

#include <sys/types.h>	// uint32_t
#if defined(_MSC_VER)
typedef unsigned __int64 uint64_t;
typedef unsigned __int32 uint32_t;
#else
#include <stdint.h>	// uint32_t
#endif

#include <cctype>
#include <cstdlib>	// NULL

// Utilities here must NOT require SystemC headers!

//=============================================================================
// Switches

//#define WAVES		// Must be defined to do waveform tracing
#if VM_TRACE		// Verilator tracing requested
# define WAVES 1	// So, trace in SystemC too
#endif

//#define SP_COVERAGE	// Must be defined to do coverage analysis
#if VM_COVERAGE		// Verilator coverage requested
# define SP_COVERAGE 1	// So, coverage in SystemC too
#endif

//=============================================================================
// Compiler pragma abstraction

#ifdef __GNUC__
# define SP_ATTR_PRINTF(fmtArgNum) __attribute__ ((format (printf, fmtArgNum, fmtArgNum+1)))
# define SP_ATTR_ALIGNED(alignment) __attribute__ ((aligned (alignment)))
# define SP_ATTR_NORETURN __attribute__ ((noreturn))
# define SP_ATTR_UNUSED __attribute__ ((unused))
# define SP_LIKELY(x)	__builtin_expect(!!(x), 1)
# define SP_UNLIKELY(x)	__builtin_expect(!!(x), 0)
#else
# define SP_ATTR_PRINTF(fmtArgNum)	///< Function with printf format checking
# define SP_ATTR_ALIGNED(alignment)	///< Align structure to specified byte alignment
# define SP_ATTR_NORETURN		///< Function does not ever return
# define SP_ATTR_UNUSED			///< Function that may be never used
# define SP_LIKELY(x)	(!!(x))		///< Boolean expression more often true than false
# define SP_UNLIKELY(x)	(!!(x))		///< Boolean expression more often false than true
#endif

//=============================================================================
/// Report SystemPerl internal error message and abort
#if defined(UERROR) && defined(UERROR_NL)
# define SP_ABORT(msg) { UERROR(msg); }
#else
# define SP_ABORT(msg) { cerr<<msg; abort(); }
#endif

#ifndef SP_ERROR_LN
/// Print error message and exit, redefine if you want something else...
# define SP_ERROR_LN(file,line,stmsg) { cout<<"%Error:"<<file<<":"<<dec<<line<<": "<<stmsg<<endl; abort();}
#endif
#ifndef SP_NOTICE_LN
/// Print notice message and non-exit, redefine if you want something else...
# define SP_NOTICE_LN(file,line,stmsg) { cout<<"%Notice:"<<file<<":"<<dec<<line<<": "<<stmsg<<endl; }
#endif

//=============================================================================
/// Conditionally compile coverage code

#ifdef SP_COVERAGE
# define SP_IF_COVER(stmts) do { stmts ; } while(0)
#else
# define SP_IF_COVER(stmts) do { if(0) { stmts ; } } while(0)
#endif

//********************************************************************
// Simple classes.  If get bigger, move to optional include

// Some functions may be used by generic C compilers!
#ifdef __cplusplus

/// Templated class which constructs to zero.
/// Originally used for easy pre-zeroing of data used for SpCoverage.
/// SystemPerl 1.301 and later always zero the points when they are added.
template <class T> class SpZeroed { public:
    T m_v;
    SpZeroed(): m_v(0) {};
    inline operator const T () const { return m_v; };
    inline SpZeroed& operator++() {++m_v; return *this;};	// prefix
    // There is no post-increment; pre-increment may be faster.
};

/// Uint32_t which constructs to zero.  (Backward compatible)
typedef SpZeroed<uint32_t> SpUInt32Zeroed;

#endif // __cplusplus

//=============================================================================

#endif // guard
