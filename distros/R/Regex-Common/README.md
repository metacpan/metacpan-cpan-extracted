# regex-common

Common regular expressions used with Perl.

## About

### Forked project!

This project is a fork from [Regexp::Common](https://metacpan.org/pod/Regexp::Common).

Looks like the original project is not being maintained anymore. This module is
intended to be executed on modern perl versions, so new features provides by
them are expected to be in place too.

See the `dist.ini` file to check what versions of perl are supported.

### The details

By default, this module exports a single hash (`%RE`) that stores or generates
commonly needed regular expressions. Patterns currently provided include:

* balanced parentheses and brackets
* delimited text (with escapes)
* integers and floating-point numbers in any base (up to 36)
* comments in 44 languages
    * offensive language
* lists of any pattern
* IPv4 addresses
    * URIs.
    * Zip codes.

Future releases of the module will also provide patterns for the following:

* email addresses
* HTML/XML tags
* mail headers (including multiline ones),
* more URIs
* telephone numbers of various countries
* currency (universal 3 letter format, Latin-1, currency names)
* dates
* binary formats (e.g. UUencoded, MIMEd)
* credit card numbers

## How to use it

```perl
use Regexp::Common;

while (<>) {
    /$RE{num}{real}/
        and print q{a number\n};
    /$RE{quoted}/
        and print q{a ['"`] quoted string\n};
    /$RE{delimited}{-delim=>'/'}/
        and print q{a /.../ sequence\n};
    /$RE{balanced}{-parens=>'()'}/
        and print q{balanced parentheses\n};
    /$RE{profanity}/
        and print q{a #*@%-ing word\n};
}
```

## To do

- Migrate tests to `Test::More` framework
- URIs:
    + As defined in RFC 1738.
    + More of them.
- Dates:
    + localtime dates.
    + ISO Dates.
    + An inverse of strftime?
- numbers:
    + Decimal numbers (e.g. 7.5, 0.3, .99, 15, but not 1.23E5).
    + Roman numbers >= 4000. Unicode?
    + Prime numbers? Fibonacci? Other special numbers?
    + Ranges of numbers.
- postal codes.
    + Lots more, especially British and Canadians.
- Email addresses.
    + RFC 822/2822.

## License

## Copyright and licence

This software is copyright (c) 2024 of Alceu Rodrigues de Freitas Junior,
glasswalk3r at yahoo.com.br

This file is part of regex-common project.

regex-commonis free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

regex-common is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
regex-common. If not, see (http://www.gnu.org/licenses/).

The original project [Regexp::Common](https://metacpan.org/pod/Regexp::Common)
is licensed through the MIT License, copyright (c) Damian Conway
(damian@cs.monash.edu.au) and Abigail (regexp-common@abigail.be).
