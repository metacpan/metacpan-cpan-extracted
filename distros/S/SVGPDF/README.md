# *SVGPDF - Produce PDF from SVG images*

![Version](https://img.shields.io/github/v/release/sciurius/SVGPDF)
![GitHub issues](https://img.shields.io/github/issues/sciurius/SVGPDF)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![Language Perl](https://img.shields.io/badge/Language-Perl-blue)

# SVGPDF

This module implements a subset of SVG to produce PDF XObjects. It
works with PDF::API and PDF::Builder.

**NOTICE:** While providing useful support for basic SVG
functionality, this library is far from a complete implementation of
SVG or CSS. Many SVG files found _in the wild_ will work, but others
will find it lacks needed features. Use at your own risk,
understanding what SVG features you need and what SVGPDF provides.

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install
	
You also need PDF::API2 version 2.043 or later, or PDF::Builder 3.027
or later.

# SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-SVGPDF.

You can find documentation for this module with the perldoc command.

    perldoc SVGPDF

Please report any bugs or feature requests using the issue tracker on
GitHub.


# COPYRIGHT AND LICENCE

Copyright (C) 2022,2026 Johan Vromans

Redistribution and use in source and binary forms, with or without
modification, are permitted provided under the terms of the Simplified
BSD License.

