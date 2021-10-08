# parse-yapphp #

Parse::Yapphp, Yet Another Parser (generator for) PHP

Compiles yacc-like LALR grammars to generate PHP OO parser modules.

## COPYRIGHT ##

Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.

Copyright © 2017 William N. Braswell, Jr.

Copyright © 2018 Oliver Schieche (PHP portions)

(see the Copyright section in Yapphp.pm for usage and distribution rights)

## IMPORTANT NOTES ##

The Parse::Yapphp pod section is the main documentation and it assumes
you already have a good knowledge of yacc. If not, I suggest the GNU
Bison manual which is a very good tutorial to LALR parsing and yacc
grammar syntax.

The yapphp frontend has its own documentation using either 'perldoc yapphp'
or (on systems with man pages) 'man yapphp'.

Any help on improving those documentations is very welcome.

## DESCRIPTION ##

This is the production release of the Parse::Yapphp parser generator.

It lets you create PHP OO fully reentrant LALR(1) parser modules
(see the Yapphp.pm pod pages for more details) and has been designed to
be functionally as close as possible to yacc, but using the full power
of Perl and opened for enhancements.

It's a modification of CPANs Parse::Yapp module by Francois Desarmenien 
which creates Perl LALR(1) OO parser modules. 

## REQUIREMENTS ##

Requires perl5.004 or better :)

It is written only in Perl, with standard distribution modules, so you
don't need any compiler nor special modules.

PHP parser classes require PHP 7.0 or above to run.

## INSTALLATION ##

perl Makefile.PL
make
make test
make install

## WARRANTY ##

This software comes with absolutly NO WARRANTY of any kind. 
I just hope it can be useful.

## FEEDBACK ##

Send feedback, comments, bug reports, pizza and postcards to:

Will Braswell <wbraswell_cpan@NOSPAM.nym.hush.com>
(Remove "NOSPAM".)
