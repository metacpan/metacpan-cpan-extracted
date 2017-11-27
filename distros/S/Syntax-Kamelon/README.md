# Kamelon

Kamelon is a versatile and fully programmable textual content parser that is 
extremely well suited for syntax highlighting and code folding

Kamelon is written in Perl (5).

# Installation

 perl Makefile.PL
 
 make
 
 make test
 
 make install

The distribution contains a number of modules and scripts that use Wx.
It is not a pre-requisite for Kamelon itself. But if you want to use
the graphical interface modules that come along with the distribution
you might want to install Wx.

# kamelon executable

You can explore Kamelon's capabilities by calling the kamelon script.
The following command should get you going:

 kamelon -help

If you want to do this before installation then you do:

 perl -Mblib bin/kamelon -help

# State of development

Kamelon parsing mechanism is stable and fully developed. Documentation
is well underway but still rather spartan. There area working output
formatters based on the template toolkit. Besides a base formatter
that you can configure for just about anything (Syntax::Kamelon::Base)
there are also formatters for ANSI (Syntax::Kamelon::ANSI) and HTML4
(Syntax::Kamelon::HTML4) output.

# Development plans

Improve speed by Rewriting some core functions of Kamelon in C

Add output formatters for HTML5, PDF, RTF, ODT, etcetera

Help and support is appreciated.

# user license

This software is licensed under the GPLV3.



