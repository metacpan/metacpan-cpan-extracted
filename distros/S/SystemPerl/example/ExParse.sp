// DESCRIPTION: SystemPerl: Example source module for parser testing
// This module used for parsing testing, and isn't a good generic example
//
// Copyright 2001-2014 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the
// GNU Lesser General Public License Version 3 or the Perl Artistic License
// Version 2.0.

#sp interface
#include <systemperl.h>
/*AUTOSUBCELL_CLASS*/

struct InhLower : public sc_module {
    sc_in<bool>		inhLowerPin;
};

struct InhModule : public InhLower {
    sc_in<bool>		inhModulePin;
};

struct InhModule2 {
    sc_in<bool>		inhModule2Pin;
};

struct __MODULE__ : public InhModule, public InhModule2 {
    sc_in_clk		clk;		/* System Clock */

    /*AUTOSUBCELL_DECL*/
    /*AUTOSIGNAL*/

  public:
    /*AUTOMETHODS*/
};

//######################################################################
#sp implementation
/*AUTOSUBCELL_INCLUDE*/

SP_CTOR_IMP(__MODULE__) /*AUTOINIT*/ {
}

#ifdef NEVER_JUST_CHECKING_PARSER
struct C14SdsSdtAgent::Display : unary_function<pair<SessionId,SessionInfo*>,void> {
};
struct Mismatch : public unary_function<const Record,unsigned> {
}
#endif

// This module used for parsing testing, and isn't a good generic example
