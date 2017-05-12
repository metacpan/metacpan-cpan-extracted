# PDLA-Stats

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/PDLPorters/pdla-stats.png?branch=master)](https://travis-ci.org/PDLPorters/pdla-stats) |
| Windows | [![Build status](https://ci.appveyor.com/api/projects/status/0vyo5c507j1ig690/branch/master?svg=true)](https://ci.appveyor.com/project/zmughal/pdla-stats/branch/master) |

[![Coverage Status](https://coveralls.io/repos/PDLPorters/pdla-stats/badge.svg?branch=master&service=github)](https://coveralls.io/github/PDLPorters/pdla-stats?branch=master)
[![CPAN version](https://badge.fury.io/pl/pdla-stats.svg)](https://metacpan.org/pod/PDLA::Stats)

This is a collection of statistics modules in Perl Data Language, with a quick-start guide for non-PDLA people.

They make perldl--the simple shell for PDLA--work like a teenie weenie R, but with PDLA threading--"the fast (and automagic) vectorised iteration of 'elementary operations' over arbitrary slices of multidimensional data"--on procedures including t-test, ordinary least squares regression, and kmeans.

Of course, they also work in perl scripts.

## DEPENDENCIES

- PDLA

  Perl Data Language. Preferably installed with a Fortran compiler. A few methods (logistic regression and all plotting methods) will only work with a Fortran compiler and some methods (ordinary least squares regression and pca) work much faster with a Fortran compiler.

  The recommended PDLA version is 2.4.8. PDLA-2.4.7 introduced a bug in lu_decomp() which caused a few functions in PDLA::Stats::GLM to fail. Otherwise the minimum compatible PDLA version is 2.4.4.

- GSL (Optional)

  GNU Scientific Library. This is required by PDLA::Stats::Distr and PDLA::GSL::CDF, the latter of which provides p-values for PDLA::Stats::GLM. GSL is otherwise NOT required for the core PDLA::Stats modules to work, ie Basic, Kmeans, and GLM.

- PGPLOT (Optional)

  PDLA-Stats currently uses PGPLOT for plotting. There are three pgplot/PGPLOT modules, which cause much confusion upon installation. First there is the pgplot Fortran library. Then there is the perl PGPLOT module, which is the perl interface to pgplot. Finally there is PDLA::Graphics::PGPLOT, which depends on pgplot and PGPLOT, that PDLA-Stats uses for plotting.

## INSTALLATION

### *nix

For standard perl module installation in *nix environment form source, to install all included modules, extract the files from the archive by entering this at a shell,

    tar xvf PDLA-Stats-xxx.tar.gz

then change to the PDLA-Stats directory,

    cd PDLA-Stats-xxx

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

then add /home/user/my_perl_lib to your PERL5LIB environment variable.

If you have trouble installing PDLA, you can look for help at the PDLA wiki or PDLA mailing list.

### Windows

Thanks to Sisyphus, Windows users can download and install the ppm version of PDLA-Stats and all dependencies using the PPM utility included in ActiveState perl or Strawberry perl. You can also get the PPM utility from CPAN.

    ppm install http://www.sisyphusion.tk/ppm/PGPLOT.ppd
    ppm install http://www.sisyphusion.tk/ppm/PDLA.ppd
    ppm install http://www.sisyphusion.tk/ppm/PDLA-Stats.ppd


## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for the modules with the
perldoc command.

    perldoc PDLA::Stats
    perldoc PDLA::Stats::Basic

etc.

You can also look for information at:

    Home
      http://pdl-stats.sourceforge.net

    Search CPAN
      http://search.cpan.org/dist/PDLA-Stats/

    Mailing list
      https://lists.sourceforge.net/lists/listinfo/pdl-stats-help

If you notice a bug or have a request, please submit a report at

      http://sourceforge.net/projects/pdl-stats/support

If you would like to help develop or maintain the package, please email me at the address below.


## COPYRIGHT AND LICENCE

Copyright (C) 2009-2012 Maggie J. Xiong  <maggiexyz users.sourceforge.net>

All rights reserved. There is no warranty. You are allowed to redistribute this software / documentation as described in the file COPYING in the PDLA distribution.
