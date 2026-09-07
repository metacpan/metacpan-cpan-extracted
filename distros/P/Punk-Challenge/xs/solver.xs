MODULE = Punk::Challenge    PACKAGE = Punk::Challenge::Solver

# solve($puzzle, %opts): the solution string, or undef when `max` nonces
# were tried without one. A function, not a method: there is no object and
# nothing to configure. NEVER FROM A HANDLER - see the POD.

SV *
solve(puzzle, ...)
        SV *puzzle
    CODE:
    {
        static const char *const known[] = { "max", NULL };
        HV *in = pchal_args(aTHX_ "solve", &ST(1), items - 1);
        STRLEN pl = 0;
        const char *pp = "";
        IV max;
        SV *r;
        pchal_check_opts(aTHX_ "option", in, known);
        max = pchal_opt_iv(aTHX_ in, "max", 0, 0, IV_MAX);
        if (SvOK(puzzle)) pp = SvPV_const(puzzle, pl);
        r = pchal_solve(aTHX_ pp, pl, (UV)max);
        RETVAL = r ? r : newSV(0);
    }
    OUTPUT:
        RETVAL
