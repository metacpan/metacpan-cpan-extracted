Perl-Critic-Policy-Perlsecret
=============================

[![Build Status](https://travis-ci.org/lancew/Perl-Critic-Policy-Perlsecret.png?branch=master)](https://travis-ci.org/lancew/Perl-Critic-Policy-Perlsecret)
[![Coverage Status](https://coveralls.io/repos/lancew/Perl-Critic-Policy-Perlsecret/badge.png?branch=master)](https://coveralls.io/r/lancew/Perl-Critic-Policy-Perlsecret?branch=master)
[![Kwalitee](http://cpants.cpanauthors.org/dist/Perl-Critic-Policy-Perlsecret.png)](http://cpants.cpanauthors.org/dist/Perl-Critic-Policy-Perlsecret)



Perlcritic policy to prevent the "interesting" operators and constants from [perlsecret](https://metacpan.org/pod/distribution/perlsecret/lib/perlsecret.pod).

Inspired by [jraspass](https://github.com/JRaspass) and code modelled on Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection This page helped too http://www.chrisdolan.net/madmongers/perlcritic.html

Inspration fostered on [questhub.io](https://questhub.io/realm/perl/quest/528cf35f9f567a6a0700006a)

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

	perldoc Perl::Critic::Policy::Perlcritic


You can also look for information at:

 * [GitHub (report bugs here)]
   (https://github.com/lancew/Perl-Critic-Policy-Perlsecret)

 * [AnnoCPAN, Annotated CPAN documentation]
   (http://annocpan.org/dist/Perl-Critic-Policy-Perlsecret)

 * [CPAN Ratings]
   (http://cpanratings.perl.org/d/Perl-Critic-Policy-Perlsecret)

 * [MetaCPAN]
   (https://metacpan.org/release/Perl-Critic-Policy-Perlsecret)


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2014 Lance Wicks

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see http://www.gnu.org/licenses/
