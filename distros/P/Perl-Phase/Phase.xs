/*
*
* Copyright (c) 2018, Nicolas R.
*
* This is free software; you can redistribute it and/or modify it under the
* same terms as Perl itself.
*
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <embed.h>

MODULE = Perl__Phase       PACKAGE = Perl::Phase

SV*
current_phase()
PPCODE:
{
    XPUSHs(newSViv(PL_phase));
}

BOOT:
    {
         HV *stash;

         stash = gv_stashpvn("Perl::Phase", 11, TRUE);

         newCONSTSUB(stash, "_loaded", &PL_sv_yes );

         newCONSTSUB(stash, "PERL_PHASE_CONSTRUCT",  newSViv(PERL_PHASE_CONSTRUCT) );
         newCONSTSUB(stash, "PERL_PHASE_START",      newSViv(PERL_PHASE_START) );
         newCONSTSUB(stash, "PERL_PHASE_CHECK",      newSViv(PERL_PHASE_CHECK) );
         newCONSTSUB(stash, "PERL_PHASE_INIT",       newSViv(PERL_PHASE_INIT) );
         newCONSTSUB(stash, "PERL_PHASE_RUN",        newSViv(PERL_PHASE_RUN) );
         newCONSTSUB(stash, "PERL_PHASE_END",        newSViv(PERL_PHASE_END) );
         newCONSTSUB(stash, "PERL_PHASE_DESTRUCT",   newSViv(PERL_PHASE_DESTRUCT) );
    }
