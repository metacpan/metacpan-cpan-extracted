# PDL-Stats

|  Build status |
| ------------- |
| ![Build Status](https://github.com/PDLPorters/PDL-Stats/workflows/perl/badge.svg?branch=master) |

[![Coverage Status](https://coveralls.io/repos/PDLPorters/PDL-Stats/badge.svg?branch=master&service=github)](https://coveralls.io/github/PDLPorters/PDL-Stats?branch=master)
[![CPAN version](https://badge.fury.io/pl/PDL-Stats.svg)](https://metacpan.org/pod/PDL::Stats)


This is a collection of statistics modules in Perl Data Language, with a quick-start guide for non-PDL people.

They make perldl--the simple shell for PDL--work like a teenie weenie R, but with PDL broadcasting--"the fast (and automagic) vectorised iteration of 'elementary operations' over arbitrary slices of multidimensional data"--on procedures including t-test, ordinary least squares regression, and kmeans.

Of course, they also work in perl scripts.

## DEPENDENCIES

- PDL

  Perl Data Language.

  The required PDL version is 2.096.

- PDL::GSL (Optional)

  PDL interface to GNU Scientific Library. This provides PDL::Stats::Distr
  and PDL::GSL::CDF, the latter of which provides p-values for
  PDL::Stats::GLM. GSL is otherwise NOT required for the core PDL::Stats
  modules to work, ie Basic, Kmeans, and GLM.

- PDL::Graphics::Simple (Optional)

  PDL-Stats currently uses this for plotting. It can use any of several
  engines to achieve this.

## INSTALLATION

### \*nix

For standard perl module installation in \*nix environment form source, to install all included modules, extract the files from the archive by entering this at a shell,

    tar xvf PDL-Stats-xxx.tar.gz

then change to the PDL-Stats directory,

    cd PDL-Stats-xxx

and run the following commands:

    perl Makefile.PL
    make
    make test
    sudo make install

If you don't have permission to run sudo, you can specify an alternative path,

    perl Makefile.PL PREFIX=/home/user/my_perl_lib
    make
    make test
    make install

then add `/home/user/my_perl_lib` to your PERL5LIB environment variable.

If you have trouble installing PDL, you can look for help at the PDL wiki or PDL mailing list.

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for the modules with the
perldoc command.

    perldoc PDL::Stats
    perldoc PDL::Stats::Basic

etc.

You can also look for information at:

    Home
      https://github.com/PDLPorters/PDL-Stats

    Search CPAN
      https://metacpan.org/dist/PDL-Stats

    Mailing list (low traffic, open a GitHub issue instead)
      https://lists.sourceforge.net/lists/listinfo/pdl-stats-help

If you notice a bug or have a request, please submit a report at

[https://github.com/PDLPorters/PDL-Stats/issues](https://github.com/PDLPorters/PDL-Stats/issues)

If you would like to help develop or maintain the package, please email me at the address below.

## COPYRIGHT AND LICENCE

Copyright (C) 2009-2012 Maggie J. Xiong  <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDL distribution.
