perl-Number-UN
======

This perl module presents an interface for details about UN numbers.

Example
-------

```perl
use Number::UN 'get_un';

my %un = get_un(1993);
print $un{description}; # Combustible liquids, n.o.s.
```

What is a UN number?
--------------------

    UN numbers or UN IDs are four-digit numbers that identify hazardous substances, and
    articles (such as explosives, flammable liquids, toxic substances, etc.) in the
    framework of international transport. Some hazardous substances have their own UN
    numbers (e.g. acrylamide has UN2074), while sometimes groups of chemicals or
    products with similar properties receive a common UN number (e.g. flammable liquids,
    not otherwise specified, have UN1993). A chemical in its solid state may receive a
    different UN number than the liquid phase if their hazardous properties differ
    significantly; substances with different levels of purity (or concentration in
    solution) may also receive different UN numbers.
    
From [UN number - Wikipedia](http://en.wikipedia.org/wiki/UN_number), 16 Feb 2012.

Licenses
--------

The source code is distributed under the [Perl5/Artistic License](http://dev.perl.org/licenses/artistic.html), copyright John Tantalo (2012).

The data material (see `lib/Number/UN-data/`) is distributed under the [Creative Commons Attribution-ShareAlike License](http://en.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License). This material was collected from [List of UN numbers - Wikipedia](http://en.wikipedia.org/wiki/List_of_UN_numbers), 16 Feb 2012.

