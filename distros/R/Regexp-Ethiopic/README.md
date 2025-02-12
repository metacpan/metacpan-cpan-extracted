# `Regexp::Ethiopic`
Regular Expressions Support for Ethiopic Script and the Languages that use it.

This repo archives the source code for the `Regexp::Ethiopic` package which was
initially submitted to CPAN on March 3, 2003. Aside from minor maintenance
as needed, no development is planned other than (eventual) expansion of
coverage to all of Ethiopic introduced in the Unicode standard since 2003.

See the provided [manual](https://htmlpreview.github.io/?https://github.com/dyacob/Regexp-Ethiopic/blob/main/doc/index.html) for 
a review of the regex approach and explanation of usage.

The `Regexp::Ethiopic` package has a CPAN home [here.](https://metacpan.org/dist/Regexp-Ethiopic) with
more terse [documentation.](https://metacpan.org/pod/Regexp::Ethiopic)

The `Regexp::Ethiopic` package provides POSIX style character class
support for Ethiopic script and the languages that use it.  The
RE symbology of the package is experimental and may change later.
The character classes themselves are stable.

Only Amharic RE support is provided until the package stabilizes
a bit.  In essence, what the package does is overload Perl's RE
mechanism to filter the convenient POSIX style classes and
convert them into big ungainly expressions that you would never
care to type.

See the files in doc/ and examples/ to get the gist of it.

The package is only known to work with Perl 5.8.0, it won't win
any points for efficiency, does not do error checking, etc, it
should be considered experimental at this time but does work
under normal conditions (ie you're not trying to break it).

Released today in case I'm hit by a bus tomorrow...
