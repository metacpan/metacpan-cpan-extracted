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
/// \brief SystemPerl Functors
///
/// AUTHOR:  Wilson Snyder
///
/// This allows you to declare a named function and later invoke that function.
/// Multiple functions may have the same name, all will be called when that
/// name is invoked.  This is like hooks in Emacs.
///
/// For example:
///	 class x {
///	     void myfunc ();
///	     ...
///	     x() { // constructor
///	        SpFunctorNamed::add("do_it", &myfunc);
///
/// Then you can invoke
///		SpFunctorNamed::call("do_it");
///
/// Which will call x_this->myfunc()
///
//=============================================================================

#ifndef _VLFUNCTOR_H_
#define _VLFUNCTOR_H_ 1

#include "SpCommon.h"
using namespace std;

//=============================================================================
// SpFunctor
///  SystemPerl function operator
////
/// Class containing a function we may operate upon.

class SpFunctor {
  public:
    SpFunctor() {};
    virtual void call(void* userdata) = 0;
    virtual ~SpFunctor() {};
};

///  SpFunctor templated for a specific class
template <class T> class SpFunctorSpec : public SpFunctor {
    void (T::*m_cb)(void* userdata);	// Pointer to method function
    T*	m_obj;		// Module object to invoke on
  public:
    typedef void (T::*Func)(void*);
    SpFunctorSpec(T* obj, void (T::*cb)(void*)) : m_cb(cb), m_obj(obj) {}
    virtual void call(void* userdata) { (*m_obj.*m_cb)(userdata); }
    virtual ~SpFunctorSpec() {}
};

//=============================================================================
// SpFunctorNamed
///  SystemPerl function operators with named access
////
/// SpFunctorNamed stores a list of SpFunctors to be operated upon, referenced
/// by a callback name.  After a function is added under the specified name,
/// all functions under that name may be called by another application.

class SpFunctorNamed {
public:
    // CREATORS:
    /// Add a SpFunctor to be callable by given name, with this class
  template <class T>
    static void add(const char* funcName, void (T::*cb)(void* userdata), T* that) {
      add(funcName, new SpFunctorSpec<T>(that,cb));
    }

    /// Add a SpFunctor to be callable by given name
    static void add(const char* funcName, SpFunctor* ftor);

    // INVOCATION:
    /// Call all functions with given name
    static void call(const char* funcName) {call(funcName,NULL);}
    /// Call all functions with given name, with userdata
    static void call(const char* funcName, void* userdata);
};

#endif // guard
