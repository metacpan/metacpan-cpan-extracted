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
/// \brief C++ Tracing in VCD Format
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================
// SPDIFF_OFF

#ifndef _SPTRACEVCDC_H_
#define _SPTRACEVCDC_H_ 1

// Note cannot include systemperl.h, or we won't work with non-SystemC compiles
#include "SpCommon.h"

#include <iostream>
#include <fstream>
#include <string>
#include <algorithm>
#include <vector>
#include <map>
using namespace std;

#define SPTRACEVCDC_VERSION 1344	// Version number of this file AS_AN_INTEGER

class SpTraceVcd;
class SpTraceCallInfo;

// SPDIFF_ON
//=============================================================================
// SpTraceVcdSig
/// Internal data on one signal being traced.

class SpTraceVcdSig {
protected:
    friend class SpTraceVcd;
    uint32_t		m_code;		///< VCD file code number
    int			m_bits;		///< Size of value in bits
    SpTraceVcdSig (uint32_t code, int bits)
	: m_code(code), m_bits(bits) {}
public:
    ~SpTraceVcdSig() {}
};

//=============================================================================

typedef void (*SpTraceCallback_t)(SpTraceVcd* vcdp, void* userthis, uint32_t code);

//=============================================================================
// SpTraceVcd
/// Base class to create a Verilator VCD dump
/// This is an internally used class - see SpTraceVcdCFile for what to call from applications

class SpTraceVcd {
private:
    bool 		m_isOpen;	///< True indicates open file
    bool		m_evcd;		///< True for evcd format
    int			m_fd;		///< File descriptor we're writing to
    string		m_filename;	///< Filename we're writing to (if open)
    uint64_t		m_rolloverMB;	///< MB of file size to rollover at
    char		m_scopeEscape;	///< Character to separate scope components
    int			m_modDepth;	///< Depth of module hierarchy
    bool		m_fullDump;	///< True indicates dump ignoring if changed
    uint32_t		m_nextCode;	///< Next code number to assign
    string		m_modName;	///< Module name being traced now
    double		m_timeRes;	///< Time resolution (ns/ms etc)
    double		m_timeUnit;	///< Time units (ns/ms etc)
    uint64_t		m_timeLastDump;	///< Last time we did a dump

    char*		m_wrBufp;	///< Output buffer
    char*		m_wrFlushp;	///< Output buffer flush trigger location
    char*		m_writep;	///< Write pointer into output buffer
    uint64_t		m_wrChunkSize;	///< Output buffer size
    uint64_t		m_wroteBytes;	///< Number of bytes written to this file

    uint32_t*			m_sigs_oldvalp;	///< Pointer to old signal values
    vector<SpTraceVcdSig>	m_sigs;		///< Pointer to signal information
    vector<SpTraceCallInfo*>	m_callbacks;	///< Routines to perform dumping
    typedef map<string,string>	NameMap;
    NameMap*			m_namemapp;	///< List of names for the header
    static vector<SpTraceVcd*>	s_vcdVecp;	///< List of all created traces

    void bufferResize(uint64_t minsize);
    void bufferFlush();
    inline void bufferCheck() {
	// Flush the write buffer if there's not enough space left for new information
	// We only call this once per vector, so we need enough slop for a very wide "b###" line
	if (SP_UNLIKELY(m_writep > m_wrFlushp)) {
	    bufferFlush();
	}
    }
    void closePrev();
    void closeErr();
    void openNext();
    void makeNameMap();
    void deleteNameMap();
    void printIndent (int levelchange);
    void printStr (const char* str);
    void printQuad (uint64_t n);
    void printTime (uint64_t timeui);
    void declare (uint32_t code, const char* name, const char* wirep,
		  int arraynum, bool tri, bool bussed, int msb, int lsb);

    void dumpHeader();
    void dumpPrep (uint64_t timeui);
    void dumpFull (uint64_t timeui);
    // cppcheck-suppress functionConst
    void dumpDone ();
    inline void printCode (uint32_t code) {
	if (code>=(94*94*94)) *m_writep++ = ((char)((code/94/94/94)%94+33));
	if (code>=(94*94))    *m_writep++ = ((char)((code/94/94)%94+33));
	if (code>=(94))       *m_writep++ = ((char)((code/94)%94+33));
	*m_writep++ = ((char)((code)%94+33));
    }
    static string stringCode (uint32_t code) {
	string out;
	if (code>=(94*94*94)) out += ((char)((code/94/94/94)%94+33));
	if (code>=(94*94))    out += ((char)((code/94/94)%94+33));
	if (code>=(94))       out += ((char)((code/94)%94+33));
	return out + ((char)((code)%94+33));
    }

protected:
    // METHODS
    void evcd(bool flag) { m_evcd = flag; }

public:
    // CREATORS
    SpTraceVcd () : m_isOpen(false), m_rolloverMB(0), m_modDepth(0), m_nextCode(1) {
	m_namemapp = NULL;
	m_timeRes = m_timeUnit = 1e-9;
	m_timeLastDump = 0;
	m_sigs_oldvalp = NULL;
	m_evcd = false;
	m_scopeEscape = '.';  // Backward compatibility
	m_fd = 0;
	m_fullDump = true;
	m_wrChunkSize = 8*1024;
	m_wrBufp = new char [m_wrChunkSize*8];
	m_wrFlushp = m_wrBufp + m_wrChunkSize * 6;
	m_writep = m_wrBufp;
	m_wroteBytes = 0;
    }
    ~SpTraceVcd();

    // ACCESSORS
    /// Inside dumping routines, return next VCD signal code
    uint32_t nextCode() const {return m_nextCode;}
    /// Set size in megabytes after which new file should be created
    void rolloverMB(uint64_t rolloverMB) { m_rolloverMB=rolloverMB; };
    /// Is file open?
    bool isOpen() const { return m_isOpen; }
    /// Change character that splits scopes.  Note whitespace are ALWAYS escapes.
    void scopeEscape(char flag) { m_scopeEscape = flag; }
    /// Is this an escape?
    inline bool isScopeEscape(char c) { return isspace(c) || c==m_scopeEscape; }

    // METHODS
    void open (const char* filename);	///< Open the file; call isOpen() to see if errors
    void openNext (bool incFilename);	///< Open next data-only file
    void flush() { bufferFlush(); }	///< Flush any remaining data
    static void flush_all();		///< Flush any remaining data from all files
    void close ();			///< Close the file

    void set_time_unit (const char* unit); ///< Set time units (s/ms, defaults to ns)
    void set_time_unit (const string& unit) { set_time_unit(unit.c_str()); }

    void set_time_resolution (const char* unit); ///< Set time resolution (s/ms, defaults to ns)
    void set_time_resolution (const string& unit) { set_time_resolution(unit.c_str()); }

    double timescaleToDouble (const char* unitp);
    string doubleToTimescale (double value);

    /// Inside dumping routines, called each cycle to make the dump
    void dump     (uint64_t timeui);
    /// Call dump with a absolute unscaled time in seconds
    void dumpSeconds (double secs) { dump((uint64_t)(secs * m_timeRes)); }

    /// Inside dumping routines, declare callbacks for tracings
    void addCallback (SpTraceCallback_t init, SpTraceCallback_t full,
		      SpTraceCallback_t change,
		      void* userthis);

    /// Inside dumping routines, declare a module
    void module (const string name);
    /// Inside dumping routines, declare a signal
    void declBit      (uint32_t code, const char* name, int arraynum);
    void declBus      (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declQuad     (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declArray    (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declTriBit   (uint32_t code, const char* name, int arraynum);
    void declTriBus   (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declTriQuad  (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declTriArray (uint32_t code, const char* name, int arraynum, int msb, int lsb);
    void declDouble   (uint32_t code, const char* name, int arraynum);
    void declFloat    (uint32_t code, const char* name, int arraynum);
    //	... other module_start for submodules (based on cell name)

    /// Inside dumping routines, dump one signal
    void fullBit (uint32_t code, const uint32_t newval) {
	// Note the &1, so we don't require clean input -- makes more common no change case faster
	m_sigs_oldvalp[code] = newval;
	*m_writep++=('0'+(char)(newval&1)); printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    void fullBus (uint32_t code, const uint32_t newval, int bits) {
	m_sigs_oldvalp[code] = newval;
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval&(1L<<bit))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    void fullQuad (uint32_t code, const uint64_t newval, int bits) {
	(*((uint64_t*)&m_sigs_oldvalp[code])) = newval;
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval&(1ULL<<bit))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    void fullArray (uint32_t code, const uint32_t* newval, int bits) {
	for (int word=0; word<(((bits-1)/32)+1); ++word) {
	    m_sigs_oldvalp[code+word] = newval[word];
	}
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++=((newval[(bit/32)]&(1L<<(bit&0x1f)))?'1':'0');
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    void fullTriBit (uint32_t code, const uint32_t newval, const uint32_t newtri) {
	m_sigs_oldvalp[code]   = newval;
	m_sigs_oldvalp[code+1] = newtri;
	*m_writep++ = "01zz"[m_sigs_oldvalp[code]
			     | (m_sigs_oldvalp[code+1]<<1)];
	printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    void fullTriBus (uint32_t code, const uint32_t newval, const uint32_t newtri, int bits) {
	m_sigs_oldvalp[code] = newval;
	m_sigs_oldvalp[code+1] = newtri;
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++ = "01zz"[((newval >> bit)&1)
				 | (((newtri >> bit)&1)<<1)];
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    void fullTriQuad (uint32_t code, const uint64_t newval, const uint32_t newtri, int bits) {
	(*((uint64_t*)&m_sigs_oldvalp[code])) = newval;
	(*((uint64_t*)&m_sigs_oldvalp[code+1])) = newtri;
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++ = "01zz"[((newval >> bit)&1ULL)
				 | (((newtri >> bit)&1ULL)<<1ULL)];
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    void fullTriArray (uint32_t code, const uint32_t* newvalp, const uint32_t* newtrip, int bits) {
	for (int word=0; word<(((bits-1)/32)+1); ++word) {
	    m_sigs_oldvalp[code+word*2]   = newvalp[word];
	    m_sigs_oldvalp[code+word*2+1] = newtrip[word];
	}
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    uint32_t valbit = (newvalp[(bit/32)]>>(bit&0x1f)) & 1;
	    uint32_t tribit = (newtrip[(bit/32)]>>(bit&0x1f)) & 1;
	    *m_writep++ = "01zz"[valbit | (tribit<<1)];
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    void fullDouble (uint32_t code, const double newval);
    void fullFloat (uint32_t code, const float newval);

    /// Inside dumping routines, dump one signal as unknowns
    /// Presently this code doesn't change the oldval vector.
    /// Thus this is for special standalone applications that after calling
    /// fullBitX, must when then value goes non-X call fullBit.
    inline void fullBitX (uint32_t code) {
	*m_writep++='x'; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullBusX (uint32_t code, int bits) {
	*m_writep++='b';
	for (int bit=bits-1; bit>=0; --bit) {
	    *m_writep++='x';
	}
	*m_writep++=' '; printCode(code); *m_writep++='\n';
	bufferCheck();
    }
    inline void fullQuadX (uint32_t code, int bits) { fullBusX (code, bits); }
    inline void fullArrayX (uint32_t code, int bits) { fullBusX (code, bits); }

    /// Inside dumping routines, dump one signal if it has changed
    inline void chgBit (uint32_t code, const uint32_t newval) {
	uint32_t diff = m_sigs_oldvalp[code] ^ newval;
	if (SP_UNLIKELY(diff)) {
	    // Verilator 3.510 and newer provide clean input, so the below is only for back compatibility
	    if (SP_UNLIKELY(diff & 1)) {   // Change after clean?
		fullBit (code, newval);
	    }
	}
    }
    inline void chgBus (uint32_t code, const uint32_t newval, int bits) {
	uint32_t diff = m_sigs_oldvalp[code] ^ newval;
	if (SP_UNLIKELY(diff)) {
	    if (SP_UNLIKELY(bits==32 || (diff & ((1U<<bits)-1) ))) {
		fullBus (code, newval, bits);
	    }
	}
    }
    inline void chgQuad (uint32_t code, const uint64_t newval, int bits) {
	uint64_t diff = (*((uint64_t*)&m_sigs_oldvalp[code])) ^ newval;
	if (SP_UNLIKELY(diff)) {
	    if (SP_UNLIKELY(bits==64 || (diff & ((1ULL<<bits)-1) ))) {
		fullQuad(code, newval, bits);
	    }
	}
    }
    inline void chgArray (uint32_t code, const uint32_t* newval, int bits) {
	for (int word=0; word<(((bits-1)/32)+1); ++word) {
	    if (SP_UNLIKELY(m_sigs_oldvalp[code+word] ^ newval[word])) {
		fullArray (code,newval,bits);
		return;
	    }
	}
    }
    inline void chgTriBit (uint32_t code, const uint32_t newval, const uint32_t newtri) {
	uint32_t diff = ((m_sigs_oldvalp[code] ^ newval)
			 | (m_sigs_oldvalp[code+1] ^ newtri));
	if (SP_UNLIKELY(diff)) {
	    // Verilator 3.510 and newer provide clean input, so the below is only for back compatibility
	    if (SP_UNLIKELY(diff & 1)) {   // Change after clean?
		fullTriBit (code, newval, newtri);
	    }
	}
    }
    inline void chgTriBus (uint32_t code, const uint32_t newval, const uint32_t newtri, int bits) {
	uint32_t diff = ((m_sigs_oldvalp[code] ^ newval)
			 | (m_sigs_oldvalp[code+1] ^ newtri));
	if (SP_UNLIKELY(diff)) {
	    if (SP_UNLIKELY(bits==32 || (diff & ((1U<<bits)-1) ))) {
		fullTriBus (code, newval, newtri, bits);
	    }
	}
    }
    inline void chgTriQuad (uint32_t code, const uint64_t newval, const uint32_t newtri, int bits) {
	uint64_t diff = ( ((*((uint64_t*)&m_sigs_oldvalp[code])) ^ newval)
			  | ((*((uint64_t*)&m_sigs_oldvalp[code+1])) ^ newtri));
	if (SP_UNLIKELY(diff)) {
	    if (SP_UNLIKELY(bits==64 || (diff & ((1ULL<<bits)-1) ))) {
		fullTriQuad(code, newval, newtri, bits);
	    }
	}
    }
    inline void chgTriArray (uint32_t code, const uint32_t* newvalp, const uint32_t* newtrip, int bits) {
	for (int word=0; word<(((bits-1)/32)+1); ++word) {
	    if (SP_UNLIKELY((m_sigs_oldvalp[code+word*2] ^ newvalp[word])
			    | (m_sigs_oldvalp[code+word*2+1] ^ newtrip[word]))) {
		fullTriArray (code,newvalp,newtrip,bits);
		return;
	    }
	}
    }
    inline void chgDouble (uint32_t code, const double newval) {
	if (SP_UNLIKELY((*((double*)&m_sigs_oldvalp[code])) != newval)) {
	    fullDouble (code, newval);
	}
    }
    inline void chgFloat (uint32_t code, const float newval) {
	if (SP_UNLIKELY((*((float*)&m_sigs_oldvalp[code])) != newval)) {
	    fullFloat (code, newval);
	}
    }
};

//=============================================================================
// SpTraceVcdCFile
/// Create a VCD dump file in C standalone (no SystemC) simulations.

class SpTraceVcdCFile {
    SpTraceVcd		m_sptrace;	///< SystemPerl trace file being created
public:
    // CONSTRUCTORS
    SpTraceVcdCFile() {}
    ~SpTraceVcdCFile() {}
    // ACCESSORS
    /// Is file open?
    bool isOpen() const { return m_sptrace.isOpen(); }
    // METHODS
    /// Open a new VCD file
    /// This includes a complete header dump each time it is called,
    /// just as if this object was deleted and reconstructed.
    void open (const char* filename) { m_sptrace.open(filename); }
    /// Continue a VCD dump by rotating to a new file name
    /// The header is only in the first file created, this allows
    /// "cat" to be used to combine the header plus any number of data files.
    void openNext (bool incFilename=true) { m_sptrace.openNext(incFilename); }
    /// Set size in megabytes after which new file should be created
    void rolloverMB(size_t rolloverMB) { m_sptrace.rolloverMB(rolloverMB); };
    /// Close dump
    void close() { m_sptrace.close(); }
    /// Flush dump
    void flush() { m_sptrace.flush(); }
    /// Write one cycle of dump data
    void dump (uint64_t timeui) { m_sptrace.dump(timeui); }
    /// Write one cycle of dump data - backward compatible and to reduce
    /// conversion warnings.  It's better to use a uint64_t time instead.
    void dump (double timestamp) { dump((uint64_t)timestamp); }
    void dump (uint32_t timestamp) { dump((uint64_t)timestamp); }
    void dump (int timestamp) { dump((uint64_t)timestamp); }
    /// Internal class access
    inline SpTraceVcd* spTrace () { return &m_sptrace; };
};

#endif // guard
