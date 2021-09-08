# Statistics-Descriptive-PDL

Intended as a near drop-in replacement for [Statistics::Descriptive](https://metacpan.org/pod/Statistics::Descriptive) but using [PDL](http://pdl.perl.org) objects for the back end.  It will presumably be faster due to PDL's speed, but that is something that can be tested.

The weighted version is also a replacement for [Statistics::Descriptive::Weighted](https://metacpan.org/pod/Statistics::Descriptive::Weighted), but with less attention to consistency of the API.  That module also has CPAN indexing and installation issues (amongst other issues with functionality, e.g. some methods ignore the weights since they call inherited Statistics::Descriptive methods).  

Note that the weighted version uses the biased form of standard deviation, skewness and kurtosis, while the unweighted and sample weighted versions use the unbiased form (consistent with Statistics::Descriptive).

Percentiles and the median also differ in that the unweighted and sample weighted forms interpolate while the weighted form does not.  Both differ from Statistics::Descriptive.

