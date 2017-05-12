// DESCRIPTION: SystemPerl: Example "null" module
//
// Copyright 2001-2014 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the
// GNU Lesser General Public License Version 3 or the Perl Artistic License
// Version 2.0.

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

SC_MODULE (__MODULE__) {

    // Pull specific I/Os from ExMod
    /*AUTOINOUT_MODULE(ExMod)*/

#sp ifdef NEVER
    // Other examples of INOUT_MODULE
    /*AUTOINOUT_MODULE(ExMod,"clk","")*/
    /*AUTOINOUT_MODULE(ExMod,"","^in")*/
    /*AUTOINOUT_MODULE(ExMod,"","sc_clock")*/
#sp endif

  private:
    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/

  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp slow
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) /*AUTOINIT*/ {
    SP_AUTO_CTOR;

#ifdef NEVER
    out.write(0);
    /*AUTOTIEOFF*/
#endif
}

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

/*AUTOTRACE(__MODULE__)*/
