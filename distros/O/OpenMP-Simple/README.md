# p5-OpenMP::Simple

This module will provide `Inline::C` related things with conveniences for building out OpenMP power subs and runtime things. It is a goal to provide a very simple stepping stone that leads developers towards more advanced `XS` typedefs and other binding options, and if needed, `PDL`.

**It's happening! See code for current state, feedback needed!**

Current thought: OpenMP::Simple should basically be the encapsulation of:
* `Inline::C`+`Alien::OpenMP` (with `omp.h` + [auto_include](https://metacpan.org/pod/Inline::C#C-CONFIGURATION-OPTIONS))
* an addition "auto_include" that defines some helpful macros and utility functions

Example of things that will be provided to make it easier to blend OpenMP decorated `Inline::C`
into Perl programs:

* C macros that work with environmental variables managed by `OpenMP::Environment`, so that the OpenMP is responsive to the process' `%ENV` in a manner similar to running a compiled binary (here we're dealing with shared libraries prepared by `Inline::C`)
* Simplified C functions that are make it as easy as possible to convert regularized data structures into their pure C equivalent (e.g., a 2D Perl array reference of floating point values)
