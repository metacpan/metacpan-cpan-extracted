# Tcl::pTk perl module

Interface to `Tcl/Tk` with `Perl/Tk` compatible syntax

## Description
    
The `Tcl::pTk` extension (not to be confused with the "native" perl5
`Perl/Tk` extension) provides a complete interface to the whole
of `Tk` via the `Tcl` extension. It has full `perl/tk` compatible syntax for 
running existing `perl/tk` scripts, as well as direct-tcl syntax for using any other `Tcl/Tk` features.
    
See the POD documentation for more details.
    
## Install

Build in the usual way for a perl extension:

       perl Makefile.PL
       make
       make test
       make install

Tweaking `Makefile.PL` is necessary only if your `Tcl` or `Tk` include files could
not be found automatically by `Makefile.PL` script. Normally you just make
sure you have right `tcl/tk` in your path at a moment of running `Makefile.PL`
script.

This will take reasonable defaults on your system and should be ok for most
uses. In some rare cases you need to specify parameters to `Makefile.PL`, such
as pointing non-standard locations of `tcl/tk`, etc. Use `--help` option to find
out supported parameters to `Makefile.PL`:

       perl Makefile.PL --help

## License

See License, Authors sections in `Tcl/pTk.pm`, or with `perldoc Tcl::pTk` - once it
is installed - to have acknowledged on this type of information.
