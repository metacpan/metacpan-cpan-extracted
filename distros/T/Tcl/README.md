# Tcl perl module for Perl5

Interface to `Tcl` and `Tcl/Tk`

# Description

The Tcl extension provides a small but complete interface into `libtcl` and
any other Tcl-based library. It lets you create Tcl interpreters as perl5
objects, execute Tcl code in those interpreters and so on. There is a `Tcl::Tk`
extension (not to be confused with "native" perl5 Perl/Tk extension)
distributed separately which provides complete interface to the whole of Tk
via this Tcl extension, also providing full perl/Tk syntax. Another extension
to note is `Tcl::pTk`, which does the same but claims to have full perl/Tk
compatibility.

Using "tcl stubs", module could be built even without tcl-dev package
installed on system. Still, tcl (or tcl/tk) must be installed during module
build. `--nousestubs` also supported. Tcl versions 9.0, 8.6, 8.4 are actively
used and supported, 8.0 also worked well in the past.

# Install

Build in the usual way for a perl extension:

       perl Makefile.PL
       make
       make test
       make install

This will take reasonable defaults on your system and should be ok for most
uses. In some rare cases you need to specify parameters to `Makefile.PL`, such
as pointing non-standard locations of `tcl/tk`, etc. Use `--help` option to find
out supported parameters to `Makefile.PL`:

       perl Makefile.PL --help

# License

See License, Authors sections in `Tcl.pm`, or with `perldoc Tcl` - once it
is installed - to have acknowledged on this type of information.

