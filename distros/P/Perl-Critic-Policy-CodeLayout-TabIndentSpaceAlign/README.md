Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign
=================================================

[![Build Status](https://travis-ci.org/guillaumeaubert/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign.svg?branch=master)](https://travis-ci.org/guillaumeaubert/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign)
[![Coverage Status](https://coveralls.io/repos/guillaumeaubert/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign/badge.svg?branch=master)](https://coveralls.io/r/guillaumeaubert/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign?branch=master)
[![CPAN](https://img.shields.io/cpan/v/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign.svg)](https://metacpan.org/release/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign)
[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](http://dev.perl.org/licenses/)

Hard tabs are a perfectly fine way to indent code for accessibility and
usability purposes, allowing different users to tweak indentation settings to
suit their needs and habits. However, hard tabs should not be used for
formatting / aligning, as this makes the display dependent on the tab-to-space
ratio of the user.

Perl::Critic::Policy::CodeLayout::ProhibitHardTabs has a setting that allows
leading tabs, but this not not fully represent the paradigm where tabs are
reserved for indenting and spaces for formatting/aligning. In particular, it
does not prevent indenting with spaces, while this module detects and prevents
it.


INSTALLATION
------------

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install


SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

	perldoc Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign


You can also look for information at:

 * [GitHub (report bugs here)]
   (https://github.com/guillaumeaubert/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign)

 * [MetaCPAN]
   (https://metacpan.org/release/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.
