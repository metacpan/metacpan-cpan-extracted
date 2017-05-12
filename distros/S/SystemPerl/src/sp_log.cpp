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

#include <cstdarg>

#include "sp_log.h"

//**********************************************************************
// Static

list<sp_log_file*> sp_log_file::s_fileps;	///< List of open sp_log_files

//**********************************************************************
// Opening

void sp_log_file::open (const char *filename, open_mode_t append) {
    // Open main logfile
    m_filename = filename;
    m_splitNum = 0;
    open_int(filename, append);
}

void sp_log_file::open_int (string filename, open_mode_t append) {
    // Internal open, used also for split
    this->close();
    std::ofstream::open (filename.c_str(), append);
    if (std::ofstream::is_open()) {
	m_isOpen = true;
	add_file();
    }
}

//**********************************************************************
// Closing

void sp_log_file::close() {
    end_redirect();
    close_int();
}

void sp_log_file::close_int() {
    if (m_isOpen) {
        if (!this->flush()) {
            std::cerr <<"%Error: sp_log_file:close_int(): flusing writes of '" <<m_filename<<"'"<<endl;
        }
	m_isOpen = false;
	remove_file();
	std::ofstream::close();
    }
}

//**********************************************************************
// Split

void sp_log_file::split_now () {
    close_int();

    // We rename the first file, so it will be obvious we rolled.
    // This also has the nice effect of insuring downstream tools notice all revs.
    if (m_splitNum==0) {
	string newname = split_name(0);
	rename (m_filename.c_str(), newname.c_str());
	// We'll just ignore if there's an error with the rename
    }
    m_splitNum++;

    open_int(split_name(m_splitNum));
}

string sp_log_file::split_name (unsigned suffixNum) {
    string filename = m_filename;
    char rollnum[10];
    sprintf(rollnum, "_%03d", suffixNum);
    unsigned pos = filename.rfind(".log");
    if (pos == filename.length()-4) {
	// Foo.log -> Foo_###.log
	filename.erase(pos);
	filename = filename + rollnum + ".log";
    } else {
	// Foo -> Foo_###
	filename += rollnum;
    }
    return filename;
}

void sp_log_file::split_check () {
    if (isOpen() && m_splitSize && (tellp() > m_splitSize)) {
	split_now();
    }
}

//**********************************************************************
// Redirection

void sp_log_file::redirect_cout() {
    if (m_strmOldCout) {
	end_redirect();
    }
    m_tee = new sp_log_teebuf (std::cout.rdbuf(), rdbuf());

    // Save old
    m_strmOldCout = std::cout.rdbuf();
    m_strmOldCerr = std::cerr.rdbuf();
    // Redirect
    std::cout.rdbuf (m_tee);
    std::cerr.rdbuf (m_tee);
}

void sp_log_file::end_redirect() {
    if (m_strmOldCout) {
	std::cout.rdbuf (m_strmOldCout);
	std::cerr.rdbuf (m_strmOldCerr);
	m_strmOldCout = NULL;
	m_strmOldCerr = NULL;
	delete (m_tee);
    }
}

//**********************************************************************
// Flushing

void sp_log_file::add_file() {
    s_fileps.push_back(this);
}
void sp_log_file::remove_file() {
    s_fileps.remove(this);
}
void sp_log_file::flush_all() {
    // Flush every open file, or on more recent library, those we know about
    // And they call this progress? :(
    for (list<sp_log_file*>::iterator it = s_fileps.begin(); it != s_fileps.end(); ++it) {
	(*it)->flush();
    }
#if defined(__GNUC__) && __GNUC__ >= 3
#else
    std::streambuf::flush_all();
#endif
}

//**********************************************************************
// C compatibility

extern "C" void sp_log_printf(const char *format, ...) {
#if defined(__GNUC__) && __GNUC__ >= 3
    // And they call this progress? :(
    static const size_t BUFSIZE = 64*1024;
    char buffer[BUFSIZE];
    va_list ap;
    va_start (ap, format);
    vsnprintf(buffer, BUFSIZE, format, ap);
    buffer[BUFSIZE-1] = '\0';
    std::cout<<buffer;
#else
    va_list ap;
    va_start (ap, format);
    std::cout.vform (format, ap);
#endif
}

//**********************************************************************

#ifdef SP_LOG_MAIN
//make -k stream && ./stream && echo "----" && cat sim.log
int main () {
    sp_log_file simlog ("sim.log");
//    sp_log_file simlog;
//    simlog.open ("sim.log");
    simlog << "Hello simlog!\n";

    simlog.redirect_cout ();
    sp_log_printf ("%s", "Hello C\n");
    cout << "Hello C++\n";
}
#endif

//g++ -DSP_LOG_MAIN sp_log.cpp ; ./a.out && cat sim.log
