OCBNET-CSS3
===========

Perl module for CSS3 parsing, manipulation and rendering. It does this by parsing the CSS into
a DOM like structure. You then can use various methods to manipulate it and finally render it again.
It should also be possible to use it as a base for an SCSS compiler implementation.

Should be able to parse nearly any css based format (i.e. scss). We try to be as unstrict as possible
when parsing css code and blocks. If the blocks are in a known format, the node/object will automatically
be set to the specific class. This enables any implementor to define its own specific implementation (todo).

Great care has been taken to parse everything correctly (like handling escaped chars and chars in quoted
strings correctly). I think many css processors and tools ignore these edge cases. This module has been
built from ground up to actually be able to parse them correctly. The key base to this is a set of well
tested regular expressions, which may be handy for other css related tasks.

INSTALL
=======

[![Build Status](https://travis-ci.org/mgreter/OCBNET-CSS3.svg?branch=master)](https://travis-ci.org/mgreter/OCBNET-CSS3)
[![Coverage Status](https://img.shields.io/coveralls/mgreter/OCBNET-CSS3.svg)](https://coveralls.io/r/mgreter/OCBNET-CSS3?branch=master)

Standard process for building & installing modules:

```
perl Build.PL
./Build
./Build test
./Build install
```

Or, if you're on a platform (like DOS or Windows) that doesn't require the "./" notation, you can do this:

```
perl Build.PL
Build
Build test
Build install
```

Or, if [cpanminus](http://search.cpan.org/~miyagawa/App-cpanminus/) is available:

```
cpanm git://github.com/mgreter/OCBNET-CSS3.git
```

blessc
======

Rewrite the given input.css if it exceeds the IE limitations (only selectors). Adds imports and additional
stylesheets. This has been inspired by http://blesscss.com/. But this version "should" handle nested blocks.
The utility tries to act as a drop in replacement (altough not tested on real examples).

```
blessc [options] [ source | - ] [destination]
```

```
-v, --version      print version
-h, --help         print this help
-f, --force        overwrite input file
-x, --compress     "minify" @import
--no-cleanup       don\'t remove old css file before overwriting
--no-imports       disable @import on stylesheets
--no-cache-buster  turn off the cache buster
```

csslint
=======

Check the given file if it is within the IE limits (selectors and imports).

```
csslint [options] [ source | - ]
```

```
-v, --version      print version
-h, --help         print this help
```

sass2scss
=========

Converts old indented sass syntax to newer scss syntax (writes to stdout).

```
sass2scss [options] [ source | - ]
```

```
-v, --version      print version
-h, --help         print this help
-p, --pretty       pretty print output
                   repeat for c block style
```

