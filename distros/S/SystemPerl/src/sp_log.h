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
/// \brief SystemPerl: File logging, redirection of cout,cerr
///
/// AUTHOR:  Wilson Snyder
///
//********************************************************************

#ifndef _SP_LOG_H_
#define _SP_LOG_H_ 1

#include "SpCommon.h"
#include <cstdio>

#ifndef UTIL_ATTR_PRINTF
# ifdef __GNUC__
/// Declare a routine to have PRINTF format error checking
#  define UTIL_ATTR_PRINTF(fmtArgNum) __attribute__ ((format (printf, fmtArgNum, fmtArgNum+1)))
# else
#  define UTIL_ATTR_PRINTF(fmtArgNum)
# endif
#endif

// Some functions may be used by generic C compilers!
#ifdef __cplusplus
extern "C" {
#endif

    /// Print to cout, but with C style arguments
    extern void sp_log_printf(const char *format, ...) UTIL_ATTR_PRINTF(1);

#ifdef __cplusplus
}
#endif

//**********************************************************************

#ifdef __cplusplus

#include <iostream>
#include <fstream>
#include <string>
#include <sys/types.h>
#include <list>
using namespace std;

//**********************************************************************
/// Internal, echo a stream to two output streams, one to screen and one to a logfile.

class sp_log_teebuf : public std::streambuf {
public:
    typedef int int_type;
    sp_log_teebuf(std::streambuf* sb1, std::streambuf* sb2):
	m_sb1(sb1),
	m_sb2(sb2)
	{}
    int_type overflow(int_type c) {
	if (m_sb1->sputc(c) == -1 || m_sb2->sputc(c) == -1)
	    return -1;
	return c;
    }
private:
    std::streambuf* m_sb1;
    std::streambuf* m_sb2;
};

//**********************************************************************
// sp_log_file
/// Create a SystemPerl log file
////
///    Usage:
///
///	sp_log_file foo;
///	foo.open ("sim.log");
/// or	sp_log_file foo ("sim.log");
///
///	foo.redirect_cout();
///	cout << "this goes to screen and sim.log";
///
///    Eventually this will do logfile split also

class sp_log_file : public std::ofstream {
public:
    // CREATORS
    /// Create a closed log file
    sp_log_file () :
	m_strmOldCout(NULL),
	m_strmOldCerr(NULL),
	m_isOpen(false),
	m_splitSize(0) {
    }
    /// Create a open log file
    sp_log_file (const char *filename, streampos split=0) :
	m_strmOldCout(NULL),
	m_strmOldCerr(NULL),
	m_isOpen(false) {
	split_size(split);
	open(filename);
    }
    ~sp_log_file () { close(); }

    // TYPES
#if defined(__GNUC__) && __GNUC__ >= 3
    typedef ios_base::openmode open_mode_t;
# define DEFAULT_OPEN_MODE (ios_base::out|ios_base::trunc)
#else
    typedef int open_mode_t;
# define DEFAULT_OPEN_MODE 0
#endif

    // METHODS
    /// Open the logfile
    void	open (const char* filename, open_mode_t append=DEFAULT_OPEN_MODE);
    void	open (const string filename, open_mode_t append=DEFAULT_OPEN_MODE) {
	open(filename.c_str(), append);
    }
    void	close ();		///< Close the file
    void	redirect_cout ();	///< Redirect cout and cerr to logfile
    void	end_redirect ();	///< End redirection
    void	split_check ();		///< Split if needed
    void	split_now ();		///< Do a split

    static void	flush_all();		///< Flush all open logfiles

    // ACCESSORS
    bool	isOpen() const { return(m_isOpen); }	///< Is the log file open?
    void	split_size (streampos size) {	///< Set # bytes to roll at
	m_splitSize = size;
    }
    inline operator bool () const { return isOpen(); };  ///< Test operator compatible w/ostream

  private:
    // METHODS
    void	open_int (string filename, open_mode_t append=DEFAULT_OPEN_MODE);
    void	close_int ();
    string	split_name (unsigned suffixNum);
    void	add_file();
    void	remove_file();

  private:
    // STATE
    streambuf*	m_strmOldCout;		///< Old cout value
    streambuf*	m_strmOldCerr;		///< Old cerr value
    bool	m_isOpen;		///< File has been opened
    sp_log_teebuf* m_tee;		///< Teeing structure
    string	m_filename;		///< Original Filename that was opened
    streampos	m_splitSize;		///< Bytes to split at
    unsigned	m_splitNum;		///< Number of splits done
    static list<sp_log_file*> s_fileps;	///< List of current files open
};

#undef DEFAULT_OPEN_MODE

#endif /*__cplusplus*/
#endif /*_SP_LOG_H_*/
