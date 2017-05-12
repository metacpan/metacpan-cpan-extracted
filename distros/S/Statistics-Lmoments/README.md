# Statistics-Lmoments
Perl extension for L-moments

     Copyright (c) 2002- Ari Jolma. All rights reserved.
     This program is free software; you can redistribute it and/or
     modify it under the same terms as Perl itself.

ACKNOWLEDGEMENTS

array.c and array.h are taken from the Karl Glazebrook's PGPLOT
distribution.

The Fortran routines for L-moments are copyrighted by J. R. M. Hosking
(http://www.research.ibm.com/people/h/hosking/home.html). I have
downloaded the code and documentation from StatLib
http://lib.stat.cmu.edu/general/

Following distributions are supported:

  EXP     Exponential distribution
  GAM     Gamma distribution
  GEV     Generalized extreme-value distribution
  GLO     Generalized logistic distribution
  GNO     Generalized Normal (lognormal) distribution
  GPA     Generalized Pareto distribution
  GUM     Gumbel distribution
  KAP     Kappa distribution
  NOR     Normal distribution
  PE3     Pearson type III distribution
  WAK     Wakeby distribution

INSTALLATION

To install, unzip and untar the archive. In the directory created type

```
perl Makefile.pl
make
make test
make install
```

Documentation is in the module file and will be added onto
perllocal.pod as usual.
