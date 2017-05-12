// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2014 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the
// GNU Lesser General Public License Version 3 or the Perl Artistic License
// Version 2.0.

#sp interface  // Comment
#include <systemperl.h>
#include <iostream>
#include "SpCoverage.h"

/*AUTOSUBCELL_CLASS*/

class ExModSubEnum {
public:
    enum en {
	ONE=1,
	TWO,
	THREE=3, NINE=9, TWENTYSEVEN=27
    };
    /*AUTOENUM_CLASS(ExModSubEnum.en)*/
};
/*AUTOENUM_GLOBAL(ExModSubEnum.en)*/

#include <iostream>
#include <stdint.h>

// Vregs-style enum class:
class ExModSubVregsEnum {
public:
    enum en {
	INV           = 0x0,
	EXCLUSIVE     = 0x4,
	MODIFIED      = 0x5,
	SHARED        = 0x6,
	OWNED         = 0x7,
	MAX           = 0x8	///< MAXIMUM+1
    };
    enum en m_e;
    inline ExModSubVregsEnum () {}
    inline ExModSubVregsEnum (en _e) : m_e(_e) {}
    explicit inline ExModSubVregsEnum (int _e) : m_e(static_cast<en>(_e)) {}
    operator const char* () const { return ascii(); }
    operator en () const { return m_e; }
    const char* ascii() const;
    inline bool valid() const { return *ascii()!='?'; };
    class iterator {
	en m_e; public:
	inline iterator(en item) : m_e(item) {};
	iterator operator++();
	inline operator ExModSubVregsEnum () const { return ExModSubVregsEnum(m_e); }
	inline ExModSubVregsEnum operator*() const { return ExModSubVregsEnum(m_e); }
    };
    static iterator begin() { return iterator(INV); }
    static iterator end()   { return iterator(MAX); }
  };
  inline bool operator== (ExModSubVregsEnum lhs, ExModSubVregsEnum rhs) { return (lhs.m_e == rhs.m_e); }
  inline bool operator== (ExModSubVregsEnum lhs, ExModSubVregsEnum::en rhs) { return (lhs.m_e == rhs); }
  inline bool operator== (ExModSubVregsEnum::en lhs, ExModSubVregsEnum rhs) { return (lhs == rhs.m_e); }
  inline bool operator!= (ExModSubVregsEnum lhs, ExModSubVregsEnum rhs) { return (lhs.m_e != rhs.m_e); }
  inline bool operator!= (ExModSubVregsEnum lhs, ExModSubVregsEnum::en rhs) { return (lhs.m_e != rhs); }
  inline bool operator!= (ExModSubVregsEnum::en lhs, ExModSubVregsEnum rhs) { return (lhs != rhs.m_e); }
  inline bool operator< (ExModSubVregsEnum lhs, ExModSubVregsEnum rhs) { return lhs.m_e < rhs.m_e; }
  inline ostream& operator<< (ostream& lhs, const ExModSubVregsEnum& rhs) { return lhs << rhs.ascii(); }


class MySigStruct {
public:
    SP_TRACED bool	m_in;
    SP_TRACED bool	m_out;
    sc_bv<72>		m_outbx;
    MySigStruct() {}
    MySigStruct(bool i, bool o, bool ob) : m_in(i), m_out(o), m_outbx(ob) {}
};
inline bool operator== (const MySigStruct &lhs, const MySigStruct &rhs) {
    return 0==memcmp(&lhs, &rhs, sizeof(lhs)); };
inline ostream& operator<< (ostream& lhs, const MySigStruct& rhs) {
    return lhs;}

SC_MODULE (__MODULE__) {
    sc_in_clk		clk;		  // **** System Inputs
    sc_in<bool>		in;
    sc_out<sp_ui<0,0> >	out;
    sc_out<bool>	outbx;

    sc_signal<MySigStruct>	m_sigstr1;
    SP_TRACED MySigStruct	m_sigstr2;

    sc_signal<sp_ui<96,5> >	m_sigstr3;	// becomes sc_bv
    SP_TRACED sp_ui<31,-1>	m_sigstr4;	// becomes uint64_t
    SP_TRACED sp_ui<10,1>	m_sigstr5;	// becomes uint32_t

    sp_ui<96,5>		m_member3;
    sp_ui<31,-1>	m_member4;
    sp_ui<10,1>		m_member5;

    sc_signal<sp_ui<31,0> >     m_var32;
    sc_signal<sp_ui<63,0> >     m_var64;

    ExModSubEnum m_autoEnumVar;
    ExModSubVregsEnum m_vregsEnumVar;

    SP_COVERGROUP example_group (
	page = "my example coverage group";
	option per_instance = 1; // this group is covered separately per instance
	coverpoint in;
	);

    SP_COVERGROUP example_group2 (
	description = "2nd example group, \"with backslashed quotes\"";
	coverpoint in;
	coverpoint in(in_alternate_name);
	coverpoint out;
	coverpoint out(out_alt_name)[16] = [0:0x7ff] { // hex is supported
	    description = "comments for a range";
	    option radix = 16; // name the bins in hex
	};
	coverpoint out(out_alt_name2)[16] = [0:0xf] {
	    // if size is exact, bin names are truncated to just the number
	    option radix = 2; // name the bins in binary
	};
	coverpoint m_var64[0x10];
	// These require a 64-bit perl
	//coverpoint m_var64(bigaddr)[16] = [0:0xffffffffffff]; // more than 32 bits
	//coverpoint m_var64(verybigaddr)[16] = [0:0xffffffffffffffff]; // all fs
	coverpoint m_var64(bigaddr)[16] = [0:0xfffffff];
	coverpoint m_var64(verybigaddr)[16] = [0:0xffffffff];
	coverpoint m_var32 {
	    bins zero = 0;
	    bins few = [ExModSubEnum::ONE:ExModSubEnum::TWO];  // can use enums on the RHS in ranges
	    bins few = [3:5];
	    bins scatter[] = {6,9,[11:15]};     // list multiple bins
	    illegal_bins ill = 16;              // illegal bins
	    illegal_bins ill2[] = {17,[19:24]};
	    bins several[] = [90:105];     	// a bin per value in a range
	    bins dist_ranges[4] = [200:299];   	// 4 bins spread over a range
	    ignore_bins ign = 0xffc0;           // ignore bins
	    ignore_bins_func = var32_ignore_func();  // ignore bins by function
	    illegal_bins_func = var32_illegal_func();  // illegal bins by function
	    limit_func = var32_limit_func();    // change CovVise limit by function
	    bins other = default;               // named default
	};
	);

    SP_COVERGROUP vregs_enum_example (
	description = "vregs-style enum";
	coverpoint m_vregsEnumVar {
	    auto_enum_bins = ExModSubVregsEnum; // make a bin for each enum value
	};
    );

    SP_COVERGROUP timing_window_example (
	description = "example of a timing window";
	// 9 bins +/- event1 occuring 4 samples before/after event2
	window myWin(in,out,4);
	window myWin2(in,out,6) {
	    description = "windows can have descriptions";
	    page = "window page";
	    option radix = 16; // name the bins in hex
	    ignore_bins_func = window_ignore_func();
	    limit_func = window_limit_func();
	};
    );

    SP_COVERGROUP autoenum_example (
	description = "enumerated type coverage";
	// both of these coverpoints are the same; the latter is automatic
	coverpoint m_autoEnumVar {
	    description = "points can have descriptions too";
	    bins ONE = 1;
	    bins TWO = 2;
	    bins THREE = ExModSubEnum::THREE; // can use enums on the RHS
	    bins NINE = 9;
	    bins TWENTYSEVEN = 27;
	};
	coverpoint m_autoEnumVar(automatic_autoEnumVar) {
	    auto_enum_bins = ExModSubEnum; // make a bin for each enum value
	    page = "automatic enum page";
	};
	);

    SP_COVERGROUP cross_example (
	description = "cross coverage";
	coverpoint m_vregsEnumVar {
	    auto_enum_bins = ExModSubVregsEnum; // make a bin for each enum value
	};
	coverpoint m_autoEnumVar {
	    auto_enum_bins = ExModSubEnum; // make a bin for each enum value
	    description = "this text goes above the point table";
	    page = "put this table on a separate page";
	};
	cross myCross {
	    description = "this text goes above the cross table";
	    page = "put this table on another separate page";
	    rows = {m_autoEnumVar};
	    cols = {m_vregsEnumVar};
	    ignore_bins_func = cross_ignore_func();  // ignore bins by function
	    illegal_bins_func = cross_illegal_func();  // illegal bins by function
	    limit_func = cross_limit_func();    // change CovVise limit by function
	    option max_bins = 0x2000; // allow more than the usual 1024 bins
	};
	);

  private:
    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/

  public:
    /*AUTOMETHODS*/
    bool var32_ignore_func(uint64_t var32) { return (var32 % 5 == 3); } // ignore all values 3 mod 5
    bool var32_illegal_func(uint64_t var32) { return (var32 == 1000); } // illegal 1000
    uint32_t var32_limit_func(uint64_t var32) { return (var32); } // return = value

    bool window_ignore_func(uint64_t cycles) { return (cycles < 3); } // ignore all counts < 3
    uint32_t window_limit_func(uint64_t cycles) { return (cycles / 2); }

    bool cross_ignore_func(uint64_t autoenum, uint64_t vregsenum) { return (autoenum == vregsenum); }
    bool cross_illegal_func(uint64_t autoenum, uint64_t vregsenum) { return (autoenum == ExModSubEnum::NINE) && (vregsenum == ExModSubVregsEnum::MODIFIED); }
    uint32_t cross_limit_func(uint64_t autoenum, uint64_t vregsenum) { return (autoenum == ExModSubEnum::NINE) ? 9 : 123; }
};

//######################################################################
#sp slow  // Comment
/*AUTOSUBCELL_INCLUDE*/
SP_CTOR_IMP(__MODULE__) /*AUTOINIT*/ {
    SP_AUTO_CTOR;

    SP_AUTO_COVER(); // only once

    m_var64 = 0;
    m_var32 = 0;
    m_autoEnumVar = ExModSubEnum::ONE;

#sp ifdef NEVER  // Comment
    // We ignore this
    SP_CELL(ignored,IGNORED_CELL);
    SP_PIN (ignored,ignore_pin,ignore_pin);
    /*AUTO_IGNORED_IF_OFF*/
# sp ifdef NEVER_ALSO  /*Comment*/
       SP_CELL(ignored2,IGNORED2_CELL);
# sp else // Comment
       SP_CELL(ignored3,IGNORED2_CELL);
# sp endif // Comment

#sp else

# sp ifdef NEVER_ALSO
    SP_CELL(ignored3,IGNORED3_CELL);
# sp else
    SP_AUTO_COVER();
# sp endif
#sp endif

#sp ifndef NEVER
    SP_AUTO_COVER();
#sp else
    SP_CELL(ifdefoff,IGNORED_CELL);
#sp endif

    // Other coverage scheme
    SP_AUTO_COVER_CMT("Commentary");
    if (0) { SP_AUTO_COVER_CMT("Never_Occurs"); }
    if (0) { SP_AUTO_COVER_CMT_IF("Not_Possible",0); }
    SP_AUTO_COVER_CMT_IF("Always_Occurs",(1||1));  // If was just '1' SP would short-circuit the eval
    for (int i=0; i<3; i++) {
	static uint32_t coverValue = 100;
	SP_COVER_INSERT(&coverValue, "comment","Hello World",
			"instance",SpCvtToCStr(i),
			"per_instance","1" );
    }
}

//######################################################################
#sp implementation // Comment
/*AUTOSUBCELL_INCLUDE*/

//ExModSubVregsEnum
const char* ExModSubVregsEnum::ascii () const {
    switch (m_e) {
	case INV: return("INV");
	case EXCLUSIVE: return("EXCLUSIVE");
	case MODIFIED: return("MODIFIED");
	case SHARED: return("SHARED");
	case OWNED: return("OWNED");
	default: return ("?E");
    }
}

ExModSubVregsEnum::iterator ExModSubVregsEnum::iterator::operator++() {
    switch (m_e) {
	case EXCLUSIVE: /*FALLTHRU*/
	case MODIFIED: /*FALLTHRU*/
	case SHARED: m_e=ExModSubVregsEnum(m_e + 1); return *this;
	case INV: m_e=EXCLUSIVE; return *this;
	default: m_e=MAX; return *this;
    }
}

void __MODULE__::clock() {
    // Below will declare the SC_METHOD and sensitivity to the clock
    SP_AUTO_METHOD(clock, clk.pos());

    SP_AUTO_COVER1("clocking");  // not in line report
    out.write(in.read());
    outbx.write(in.read());
    m_sigstr1.write(MySigStruct(in,out,outbx));
    m_sigstr2 = MySigStruct(in,out,outbx);
    m_var64 = m_var64 + (1 << 28);
    m_var32 = m_var32 + (10);

    if (m_autoEnumVar != ExModSubEnum::NINE)
	m_autoEnumVar = ExModSubEnum((int)m_autoEnumVar + 1);

    if (m_autoEnumVar == ExModSubEnum::TWO)
	m_vregsEnumVar = ExModSubVregsEnum::MODIFIED;
    else
	m_vregsEnumVar = ExModSubVregsEnum::SHARED;

    SP_AUTO_COVER();

    SP_COVER_SAMPLE(cross_example);
    SP_COVER_SAMPLE(vregs_enum_example);
    SP_COVER_SAMPLE(timing_window_example);
    SP_COVER_SAMPLE(autoenum_example);
    SP_COVER_SAMPLE(example_group);
    if (in.read()) {
	SP_COVER_SAMPLE(example_group2);
    }
}

/*AUTOTRACE(__MODULE__)*/
