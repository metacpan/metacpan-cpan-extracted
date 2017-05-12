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
/// \brief SystemPerl Coverage analysis
///
/// AUTHOR:  Wilson Snyder
///
//=============================================================================

#include <cstdio>
#include <cstdarg>
#include <cstring>
#include <cassert>
#include "SpCoverage.h"

#include <map>
#include <deque>
#include <fstream>

//=============================================================================
// SpCoverageImpBase
/// Implementation base class for constants

struct SpCoverageImpBase {
    // TYPES
    enum { MAX_KEYS = 33 };		/// Maximum user arguments + filename+lineno
    enum { KEY_UNDEF = 0 };		/// Magic key # for unspecified values
};

//=============================================================================
// SpCoverageImpItem
/// Implementation class for a SpCoverage item

class SpCoverageImpItem : SpCoverageImpBase {
public:  // But only local to this file
    // MEMBERS
    int	m_keys[MAX_KEYS];		///< Key
    int	m_vals[MAX_KEYS];		///< Value for specified key
    // CONSTRUCTORS
    // Derived classes should call zero() in their constructor
    SpCoverageImpItem() {
	for (int i=0; i<MAX_KEYS; i++) m_keys[i]=KEY_UNDEF;
    }
    virtual ~SpCoverageImpItem() {}
    virtual uint64_t count() const = 0;
    virtual void zero() const = 0;
};

//=============================================================================
/// SpCoverItem templated for a specific class
/// Creates a new coverage item for the specified type.
/// This isn't in the header file for auto-magic conversion because it
/// inlines to too much code and makes compilation too slow.

template <class T> class SpCoverItemSpec : public SpCoverageImpItem {
private:
    // MEMBERS
    T*	m_countp;	///< Count value
public:
    // METHODS
    virtual uint64_t count() const { return *m_countp; }
    virtual void zero() const { *m_countp = 0; }
    // CONSTRUCTORS
    SpCoverItemSpec(T* countp) : m_countp(countp) { zero(); }
    virtual ~SpCoverItemSpec() {}
};

//=============================================================================
// SpCoverageImp
/// Implementation class for SpCoverage.  See that class for public method information.
/// All value and keys are indexed into a unique number.  Thus we can greatly reduce
/// the storage requirements for otherwise identical keys.

class SpCoverageImp : SpCoverageImpBase {
private:
    // TYPES
    typedef map<string,int> ValueIndexMap;
    typedef map<int,string> IndexValueMap;
    typedef deque<SpCoverageImpItem*> ItemList;

private:
    // MEMBERS
    ValueIndexMap	m_valueIndexes;		///< For each key/value a unique arbitrary index value
    IndexValueMap	m_indexValues;		///< For each key/value a unique arbitrary index value
    ItemList		m_items;		///< List of all items

    SpCoverageImpItem*	m_insertp;		///< Item about to insert
    const char*		m_insertFilenamep;	///< Filename about to insert
    int			m_insertLineno;		///< Line number about to insert

    // CONSTRUCTORS
    SpCoverageImp() {
	m_insertp = NULL;
	m_insertFilenamep = NULL;
	m_insertLineno = 0;
    }
public:
    ~SpCoverageImp() { clear(); }
    static SpCoverageImp& imp() {
	static SpCoverageImp s_singleton;
	return s_singleton;
    }

private:
    // PRIVATE METHODS
    int valueIndex(const string& value) {
	static int nextIndex = KEY_UNDEF+1;
	ValueIndexMap::iterator iter = m_valueIndexes.find(value);
	if (iter != m_valueIndexes.end()) return iter->second;
	nextIndex++;  assert(nextIndex>0);
	m_valueIndexes.insert(make_pair(value, nextIndex));
	m_indexValues.insert(make_pair(nextIndex, value));
	return nextIndex;
    }
    string dequote(const string& text) {
	// Remove any ' or newlines
	string rtn = text;
	for (string::iterator pos=rtn.begin(); pos!=rtn.end(); ++pos) {
	    if (*pos == '\'') *pos = '_';
	    if (*pos == '\n') *pos = '_';
	}
	return rtn;
    }
    bool numeric(const string& text) {
	// Remove any ' or newlines
	for (string::const_iterator pos=text.begin(); pos!=text.end(); ++pos) {
	    if (!isdigit(*pos)) return false;
	}
	return !text.empty();  // Empty string isn't numeric
    }
    bool legalKey(const string& key) {
	// Because we compress long keys to a single letter, and
	// don't want applications to either get confused if they use
	// a letter differently, nor want them to rely on our compression...
	// (Considered using numeric keys, but will remain back compatible.)
	if (key.length()<2) return false;
	if (key.length()==2 && isdigit(key[1])) return false;
	return true;
    }

    string shortKey(const string& key) {
	// Shorten keys so we get much smaller dumps
	// Note extracted from and compared with SystemC::Coverage::ItemKey
	// AUTO_EDIT_BEGIN_SystemC::Coverage::ItemKey
	if (key == "col0") return "c0";
	if (key == "col0_name") return "C0";
	if (key == "col1") return "c1";
	if (key == "col1_name") return "C1";
	if (key == "col2") return "c2";
	if (key == "col2_name") return "C2";
	if (key == "col3") return "c3";
	if (key == "col3_name") return "C3";
	if (key == "column") return "n";
	if (key == "comment") return "o";
	if (key == "count") return "c";
	if (key == "filename") return "f";
	if (key == "groupcmt") return "O";
	if (key == "groupdesc") return "d";
	if (key == "groupname") return "g";
	if (key == "hier") return "h";
	if (key == "limit") return "L";
	if (key == "lineno") return "l";
	if (key == "per_instance") return "P";
	if (key == "row0") return "r0";
	if (key == "row0_name") return "R0";
	if (key == "row1") return "r1";
	if (key == "row1_name") return "R1";
	if (key == "row2") return "r2";
	if (key == "row2_name") return "R2";
	if (key == "row3") return "r3";
	if (key == "row3_name") return "R3";
	if (key == "table") return "T";
	if (key == "thresh") return "s";
	if (key == "type") return "t";
	if (key == "weight") return "w";
#define SP_CIK_COL0 "c0"
#define SP_CIK_COL0_NAME "C0"
#define SP_CIK_COL1 "c1"
#define SP_CIK_COL1_NAME "C1"
#define SP_CIK_COL2 "c2"
#define SP_CIK_COL2_NAME "C2"
#define SP_CIK_COL3 "c3"
#define SP_CIK_COL3_NAME "C3"
#define SP_CIK_COLUMN "n"
#define SP_CIK_COMMENT "o"
#define SP_CIK_COUNT "c"
#define SP_CIK_FILENAME "f"
#define SP_CIK_GROUPCMT "O"
#define SP_CIK_GROUPDESC "d"
#define SP_CIK_GROUPNAME "g"
#define SP_CIK_HIER "h"
#define SP_CIK_LIMIT "L"
#define SP_CIK_LINENO "l"
#define SP_CIK_PER_INSTANCE "P"
#define SP_CIK_ROW0 "r0"
#define SP_CIK_ROW0_NAME "R0"
#define SP_CIK_ROW1 "r1"
#define SP_CIK_ROW1_NAME "R1"
#define SP_CIK_ROW2 "r2"
#define SP_CIK_ROW2_NAME "R2"
#define SP_CIK_ROW3 "r3"
#define SP_CIK_ROW3_NAME "R3"
#define SP_CIK_TABLE "T"
#define SP_CIK_THRESH "s"
#define SP_CIK_TYPE "t"
#define SP_CIK_WEIGHT "w"
	// AUTO_EDIT_END_SystemC::Coverage::ItemKey
	return key;
    }

    string keyValueFormatter (const string& key, const string& value) {
	string name;
	if (key.length()==1 && isalpha(key[0])) {
	    name += string("\001")+key;
	} else {
	    name += string("\001")+dequote(key);
	}
	name += string("\002")+dequote(value);
	return name;
    }

    string combineHier (const string& old, const string& add) {
	// (foo.a.x, foo.b.x) => foo.*.x
	// (foo.a.x, foo.b.y) => foo.*
	// (foo.a.x, foo.b)   => foo.*
	if (old == add) return add;
	if (old == "") return add;
	if (add == "") return old;

	const char* a = old.c_str();
	const char* b = add.c_str();

	// Scan forward to first mismatch
	const char* apre = a;
	const char* bpre = b;
	while (*apre == *bpre) { apre++; bpre++; }

	// We used to backup and split on only .'s but it seems better to be verbose
	// and not assume . is the separator
	string prefix = string(a,apre-a);

	// Scan backward to last mismatch
	const char* apost = a+strlen(a)-1;
	const char* bpost = b+strlen(b)-1;
	while (*apost == *bpost
	       && apost>apre && bpost>bpre) { apost--; bpost--; }

	// Forward to . so we have a whole word
	string suffix = *bpost ? string(bpost+1) : "";

	string out = prefix+"*"+suffix;

	//cout << "\nch pre="<<prefix<<"  s="<<suffix<<"\nch a="<<old<<"\nch b="<<add<<"\nch o="<<out<<endl;
	return out;
    }

    bool itemMatchesString(SpCoverageImpItem* itemp, const string& match) {
	for (int i=0; i<MAX_KEYS; i++) {
	    if (itemp->m_keys[i] != KEY_UNDEF) {
		// We don't compare keys, only values
		string val = m_indexValues[itemp->m_vals[i]];
		if (string::npos != val.find(match)) {  // Found
		    return true;
		}
	    }
	}
	return false;
    }

    void selftest() {
	// Little selftest
	if (combineHier ("a.b.c","a.b.c")	!="a.b.c") SP_ABORT("%Error: selftest\n");
	if (combineHier ("a.b.c","a.b")		!="a.b*") SP_ABORT("%Error: selftest\n");
	if (combineHier ("a.x.c","a.y.c")	!="a.*.c") SP_ABORT("%Error: selftest\n");
	if (combineHier ("a.z.z.z.c","a.b.c")	!="a.*.c") SP_ABORT("%Error: selftest\n");
	if (combineHier ("z","a")		!="*") SP_ABORT("%Error: selftest\n");
	if (combineHier ("q.a","q.b")		!="q.*") SP_ABORT("%Error: selftest\n");
	if (combineHier ("q.za","q.zb")		!="q.z*") SP_ABORT("%Error: selftest\n");
	if (combineHier ("1.2.3.a","9.8.7.a")	!="*.a") SP_ABORT("%Error: selftest\n");
    }

public:
    // PUBLIC METHODS
    void clear() {
	for (ItemList::iterator it=m_items.begin(); it!=m_items.end(); ++it) {
	    SpCoverageImpItem* itemp = *(it);
	    delete itemp;
	}
	m_items.clear();
	m_indexValues.clear();
	m_valueIndexes.clear();
    }
    void clearNonMatch (const char* matchp) {
	if (matchp && matchp[0]) {
	    ItemList newlist;
	    for (ItemList::iterator it=m_items.begin(); it!=m_items.end(); ++it) {
		SpCoverageImpItem* itemp = *(it);
		if (!itemMatchesString(itemp, matchp)) {
		    delete itemp;
		} else {
		    newlist.push_back(itemp);
		}
	    }
	    m_items = newlist;
	}
    }

    void zero() {
	for (ItemList::iterator it=m_items.begin(); it!=m_items.end(); ++it) {
	    (*it)->zero();
	}
    }

    // We assume there's always call to i/f/p in that order
    void inserti (SpCoverageImpItem* itemp) {
	assert(!m_insertp);
 	m_insertp = itemp;
    }
    void insertf (const char* filenamep, int lineno) {
	m_insertFilenamep = filenamep;
	m_insertLineno = lineno;
    }
    void insertp (const char* ckeyps[MAX_KEYS],
		  const char* valps[MAX_KEYS]) {
	assert(m_insertp);
	// First two key/vals are filename
	ckeyps[0]="filename";	valps[0]=m_insertFilenamep;
	SpCvtToCStr linestrp (m_insertLineno);
	ckeyps[1]="lineno";	valps[1]=linestrp;
	// Default page if not specified
	const char* fnstartp = m_insertFilenamep;
	while (const char* foundp = strchr(fnstartp,'/')) fnstartp=foundp+1;
	const char* fnendp = fnstartp;
	while (*fnendp && *fnendp!='.') fnendp++;
	string page_default = "sp_user/"+string(fnstartp,fnendp-fnstartp);
	ckeyps[2]="page";	valps[2]=page_default.c_str();

	// Keys -> strings
	string keys[MAX_KEYS];
	for (int i=0; i<MAX_KEYS; i++) {
	    if (ckeyps[i] && ckeyps[i][0]) {
		keys[i] = ckeyps[i];
	    }
	}

	// Ignore empty keys
	for (int i=0; i<MAX_KEYS; i++) {
	    if (keys[i]!="") {
		for (int j=i+1; j<MAX_KEYS; j++) {
		    if (keys[i] == keys[j]) {  // Duplicate key.  Keep the last one
			keys[i] = "";
			break;
		    }
		}
	    }
	}

	// Insert the values
	int addKeynum=0;
	for (int i=0; i<MAX_KEYS; i++) {
	    const string key = keys[i];
	    if (keys[i]!="") {
		const string val = valps[i];
		//cout<<"   "<<__FUNCTION__<<"  "<<key<<" = "<<val<<endl;
		m_insertp->m_keys[addKeynum] = valueIndex(key);
		m_insertp->m_vals[addKeynum] = valueIndex(val);
		addKeynum++;
		if (!legalKey(key)) {
		    SP_ABORT("%Error: Coverage keys of one character, or letter+digit are illegal: "<<key);
		}
	    }
	}

	m_items.push_back(m_insertp);
	// Prepare for next
	m_insertp = NULL;
    }

    void write (const char* filename) {
#ifndef SP_COVERAGE
	SP_ABORT("%Error: Called SpCoverage::write when SP_COVERAGE disabled\n");
#endif
	selftest();

	ofstream os (filename);
	if (os.fail()) {
	    SP_ABORT("%Error: Can't Write "<<filename<<endl);
	    return;
	}
	os << "# SystemC::Coverage-3\n";

	// Build list of events; totalize if collapsing hierarchy
	typedef map<string,pair<string,uint64_t> >	EventMap;
	EventMap	eventCounts;
	for (ItemList::iterator it=m_items.begin(); it!=m_items.end(); ++it) {
	    SpCoverageImpItem* itemp = *(it);
	    string name;
	    string hier;
	    bool per_instance = false;

	    for (int i=0; i<MAX_KEYS; i++) {
		if (itemp->m_keys[i] != KEY_UNDEF) {
		    string key = shortKey(m_indexValues[itemp->m_keys[i]]);
		    string val = m_indexValues[itemp->m_vals[i]];
		    if (key == SP_CIK_PER_INSTANCE) {
			if (val != "0") per_instance = true;
		    }
		    if (key == SP_CIK_HIER) {
			hier = val;
		    } else {
			// Print it
			name += keyValueFormatter(key,val);
		    }
		}
	    }
	    if (per_instance) {  // Not collapsing hierarchies
		name += keyValueFormatter(SP_CIK_HIER,hier);
		hier = "";
	    }

	    // Group versus point labels don't matter here, downstream
	    // deals with it.  Seems bad for sizing though and doesn't
	    // allow easy addition of new group codes (would be
	    // inefficient)

	    // Find or insert the named event
	    EventMap::iterator cit = eventCounts.find(name);
	    if (cit != eventCounts.end()) {
		const string& oldhier = cit->second.first;
		cit->second.second += itemp->count();
		cit->second.first  = combineHier(oldhier, hier);
	    } else {
		eventCounts.insert(make_pair(name, make_pair(hier,itemp->count())));
	    }
	}

	// Output body
	for (EventMap::iterator it=eventCounts.begin(); it!=eventCounts.end(); ++it) {
	    os<<"C '"<<dec;
	    os<<it->first;
	    if (it->second.first != "") os<<keyValueFormatter(SP_CIK_HIER,it->second.first);
	    os<<"' "<<it->second.second;
	    os<<endl;
	}

	// End
    }
};

//=============================================================================
// SpCoverage

void SpCoverage::clear() {
    SpCoverageImp::imp().clear();
}

void SpCoverage::clearNonMatch (const char* matchp) {
    SpCoverageImp::imp().clearNonMatch(matchp);
}

void SpCoverage::zero() {
    SpCoverageImp::imp().zero();
}

void SpCoverage::write (const char* filenamep) {
    SpCoverageImp::imp().write(filenamep);
}

void SpCoverage::_inserti (uint32_t* itemp) {
    SpCoverageImp::imp().inserti(new SpCoverItemSpec<uint32_t>(itemp));
}
void SpCoverage::_inserti (uint64_t* itemp) {
    SpCoverageImp::imp().inserti(new SpCoverItemSpec<uint64_t>(itemp));
}
void SpCoverage::_insertf (const char* filename, int lineno) {
    SpCoverageImp::imp().insertf(filename,lineno);
}

#define K(n) const char* key ## n
#define A(n) const char* key ## n, const char* val ## n		// Argument list
#define C(n) key ## n, val ## n	// Calling argument list
#define N(n) "",""	// Null argument list
void SpCoverage::_insertp (A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),
			   A(10),A(11),A(12),A(13),A(14),A(15),A(16),A(17),A(18),A(19),
			   A(20),A(21),A(22),A(23),A(24),A(25),A(26),A(27),A(28),A(29)) {
    const char* keyps[SpCoverageImpBase::MAX_KEYS]
	= {NULL,NULL,NULL,	// filename,lineno,page
	   key0,key1,key2,key3,key4,key5,key6,key7,key8,key9,
	   key10,key11,key12,key13,key14,key15,key16,key17,key18,key19,
	   key20,key21,key22,key23,key24,key25,key26,key27,key28,key29};
    const char* valps[SpCoverageImpBase::MAX_KEYS]
	= {NULL,NULL,NULL,	// filename,lineno,page
	   val0,val1,val2,val3,val4,val5,val6,val7,val8,val9,
	   val10,val11,val12,val13,val14,val15,val16,val17,val18,val19,
	   val20,val21,val22,val23,val24,val25,val26,val27,val28,val29};
    SpCoverageImp::imp().insertp(keyps, valps);
}

// And versions with fewer arguments  (oh for a language with named parameters!)
void SpCoverage::_insertp (A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9)) {
    _insertp(C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	     N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19),
	     N(20),N(21),N(22),N(23),N(24),N(25),N(26),N(27),N(28),N(29));
}
void SpCoverage::_insertp (A(0),A(1),A(2),A(3),A(4),A(5),A(6),A(7),A(8),A(9),
			   A(10),A(11),A(12),A(13),A(14),A(15),A(16),A(17),A(18),A(19)) {
    _insertp(C(0),C(1),C(2),C(3),C(4),C(5),C(6),C(7),C(8),C(9),
	     C(10),C(11),C(12),C(13),C(14),C(15),C(16),C(17),C(18),C(19),
	     N(20),N(21),N(22),N(23),N(24),N(25),N(26),N(27),N(28),N(29));
}
// Backward compatibility for Verilator
void SpCoverage::_insertp (A(0), A(1),  K(2),int val2,  K(3),int val3,
			   K(4),const string& val4,  A(5),A(6)) {
    _insertp(C(0),C(1),
	     key2,SpCvtToCStr(val2),  key3,SpCvtToCStr(val3),  key4, val4.c_str(),
	     C(5),C(6),N(7),N(8),N(9),
	     N(10),N(11),N(12),N(13),N(14),N(15),N(16),N(17),N(18),N(19),
	     N(20),N(21),N(22),N(23),N(24),N(25),N(26),N(27),N(28),N(29));
}
#undef A
#undef C
#undef N
#undef K
