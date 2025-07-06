# `Term::ReadLine::Gnu` --- The GNU Readline Library Wrapper Module

Copyright (c) 1996-2025 Hiroo Hayashi.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

## Description

`Term::ReadLine::Gnu` (TRG) is an implementation of the
interface to [the GNU Readline Library](https://tiswww.case.edu/php/chet/readline/rltop.html).  This module gives you
input line editing facility, input history management
facility, word completion facility, etc.  It uses the real GNU
Readline Library and has the interface with the almost all
variables and functions which are documented in [the GNU
Readline/History Library Manual](https://tiswww.case.edu/php/chet/readline/rltop.html).  So you can program your custom
editing function, your custom completion function, and so on
with Perl.  TRG may be useful for a C programmer to prototype
a program which uses the GNU Readline Library.

TRG is upper compatible with `Term::ReadLine` included in Perl
distribution.  `Term::ReadLine` uses TRG automatically when TRG
is available.  You can enjoy full line-editing feature with
Perl debugger which use `Term::ReadLine` without any additional settings.

Ilya Zakharevich has been distributing his implementation,
`Term::ReadLine::Perl`, which bases on Jeffrey Friedl's
`readline.pl`.  His module works very well, and is easy to
install because it is written by only Perl.  I tried to
make my module compatible with his.  He gave me a lot of valuable advises.
Unfortunately `readline.pl` simulated old GNU Readline
library before TRG was born.  For example, it was not 8 bit
clean and it warns to the variables in `~/.inputrc` which it did
not know yet.  We Japanese usually use 8 bit characters, so
this was a bad feature for me.  I could make a patch for these
problems but I had interest with C interface facility and
dynamic loading facility of Perl, so I thought it was a good
chance for me to study them.  Then I made this module instead
of fixing his module.

## Prerequisites

You must have Perl 5.8 or later.  If you have to use old Perl
for some reason, use `Term::ReadLine::Gnu` 1.09.  (I recommend
you to use newer Perl.)

You must have GNU Readline Library Version 2.1 or later.  See
[INSTALL](./INSTALL.md) for more detail.

A report said GNU Readline Library might not work with perl with
`sfio`, which was deprecated by Perl 5.20.

## How to build/install

See [INSTALL](./INSTALL.md).

## Bugs

There may be some bugs in both programs and documents.
Comments and bug reports are very welcome. Send me a E-Mail or
open a ticket on [the bug tracker on GitHub](https://github.com/hirooih/perl-trg/issues)

## Author

Hiroo Hayashi <hiroo.hayashi@computer.org>

## Links

- [Term::ReadLine::Gnu](https://metacpan.org/dist/Term-ReadLine-Gnu)
  - [Term::ReadLine::Gnu Users' Manual](https://metacpan.org/pod/Term::ReadLine::Gnu)
- [Term::ReadLine::Gnu GitHub Repository](https://github.com/hirooih/perl-trg)
- [The GNU Readline Library Manual](https://tiswww.cwru.edu/php/chet/readline/readline.html)
- [The GNU History Library Manual](https://tiswww.cwru.edu/php/chet/readline/history.html)
- [Term::ReadLine](https://metacpan.org/dist/Term-ReadLine)

## Revision History

See [Changes](./Changes).
