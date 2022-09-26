# perl-statistics-sampler-multinomial


Implements multinomial sampling using two methods, the
conditional binomial method, and Vose's version of the alias method
(as a separate package).

The setup time for the alias method is longer than for other methods,
and the memory requirements are larger since it maintains two lists in memory,
but this is amortised when 
when generating repeated samples because only two random numbers are
needed for each draw, as compared to up to O(log n) for other methods.
This should have a pay off when, for example calculating 
bootstrap confidence intervals for a set of classes.

However, benchmarking indicates that the conditional binomial code is
substantially (approximately four times) faster than the alias method code
when using the Mersenne Twister implemented in Math::Random::MT::Auto.
Profiling using Devel::NYTProf indicates this is probably due to
Perl level overheads for the PRNG method calls in the Alias code.
For the conditional binomial code most of the PRNG calls are
at the C level inside XS code.

Benchmarking also indicates that the Math::GSL::Randist implementation
is a few orders of magnitude faster still, so if you aren't worried about
using your own PRNG, and can install Math::GSL::Randist,
then you should consider using that.
The Math::Random implementation is also faster than this module,
but not as fast as the GSL.

So if it is not faster, then why would you use this module?
The main reason is that it allows you to pass your own
PRNG object, and thus you can continue sampling from an existing PRNG stream
within your analysis using the PRNG of your choice.
This simplifies reproducibility of results as one only
needs to store the starting state for one PRNG, not several.


For more details and background about multinomial sampling,
see http://www.keithschwarz.com/darts-dice-coins


## COPYRIGHT AND LICENCE

Copyright (C) 2016, Shawn Laffan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
