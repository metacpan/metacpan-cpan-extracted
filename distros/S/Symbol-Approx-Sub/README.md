
#Symbol::Approx::Sub#

[![Build Status](https://travis-ci.org/davorg/symbol-approx-sub.svg?branch=master)](https://travis-ci.org/davorg/symbol-approx-sub) [![Coverage Status](https://coveralls.io/repos/github/davorg/symbol-approx-sub/badge.svg?branch=master)](https://coveralls.io/github/davorg/symbol-approx-sub?branch=master)

##What is Symbol::Approx::Sub?##

Symbol::Approx::Sub is a Perl module which allows you to call subroutines
using approximate names.

Of course, why you might want to do that is a completely different
question. You almost certainly don't want to do it in production
code as it will make your program almost completely unmaintainable.

I only wrote this module to test my understanding of typeglobs and
AUTOLOAD. I really don't expect it to have any sensible uses at all
(but if you find one, I'd be interested in knowing what it is).

##How Do I Install It?

Symbol::Approx::Sub uses the standard Perl module architecture and can
therefore by installed using the standard Perl method which, in
brief, goes something like this:

```unix
   gzip -cd Symbol-Approx-Sub-X.XX.tar.gz | tar xvf -
   cd Symbol-Approx-Sub-X.XX
   perl Makefile.PL
   make
   make test
   make install
```

Where X.XX is the version number of the module which you are
installing.

If this doesn't work for you then creating a directory called
Symbol/Approx somewhere in your Perl library path (@INC) and copying
the Sub.pm file into this directory should also do the trick.


##Prerequisites##

As of version 1.03, Symbol::Approx::Sub uses Devel::Symdump to do
all of the clever glob-walking stuff, so you'll need to get that from
CPAN and install it before installing Symbol::Approx::Sub.

##Where is the Documentation?##

All of the documentation is currently in POD format in the Approx.pm
file. If you install the module using the standard method you should
be able to read it by typing

```unix
   perldoc Symbol::Approx::Sub
```

at a command prompt.

##Latest Version

The latest version of this module will always be available from
CPAN.

##Copyright##

Copyright (c) 2000, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

##Anything Else?

If you have any further questions, please contact the author.

##Authors##
Dave Cross

Email: dave@mag-sol.com
