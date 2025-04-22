# PDF::Builder release 3.027

A Perl library to create and modify PDF (Portable Document Format) files

## What is it?

PDF::Builder is a **fork** of the popular PDF::API2\* Perl library. It
provides a library of modules and functions so that a PDF file (document) may
be built and maintained from Perl programs (it can also read in, modify, and
write back out existing PDF files). It is not a WYSIWYG editor; nor is it a
canned utility or converter. It does _not_ have a GUI or command line interface
-- it is driven by _your_ Perl program. It is a set of **building blocks**
(methods) with which you can perform a wide variety of operations, ranging
from basic operations (such as selecting a font face), to defining an entire
page at a time in the document (using a large subset of either Markdown or HTML
markup languages). You can call it from arbitrary Perl programs, which may even
create content on-the-fly (or read it in from other sources). Quite a few code
examples are provided, to help you to get started with the process of creating
a PDF document. Many enhancements are in the pipeline to make PDF::Builder even
more powerful and versatile.

\*Note that PDF::Builder is **not** built on PDF::API2, and does **not**
require that it be installed. The two libraries are completely independent of
each other and one will not interfere with the other if both are installed.

**Gadzooks!** For a delightful look at the (rather grisly) origin of this
typographical term, as well as many other terms, watch
https://www.youtube.com/watch?v=cd5iFbuNKv8 .

[Home Page](https://www.catskilltech.com/FreeSW/product/PDF%2DBuilder/title/PDF%3A%3ABuilder/freeSW_full), including Documentation and Examples.

[![Open Issues](https://img.shields.io/github/issues/PhilterPaper/Perl-PDF-Builder)](https://github.com/PhilterPaper/Perl-PDF-Builder/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://makeapullrequest.com)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/PhilterPaper/Perl-PDF-Builder/graphs/commit-activity)

This archive contains the distribution PDF::Builder.
See **Changes** file for the version and list of changes from the previous 
release.

## Obtaining and Installing the Package

The installable Perl package may be obtained from
"https://metacpan.org/pod/PDF::Builder", or via a CPAN installer package. If
you install this product, only the run-time modules will be installed. Download
the full `.tar.gz` file and unpack it (uncompress, then extract directory --
hint: on Windows, **7-Zip File Manager** is an excellent tool) to get 
utilities, test buckets, example usage, etc.

Alternatively, you can obtain the full source files from
"https://github.com/PhilterPaper/Perl-PDF-Builder", where the ticket list
(bugs, enhancement requests, etc.) is also kept. Unlike the installable CPAN
version, this will have to be manually installed (copy files; there are no XS
compiles at this time).

Other than an installer for standard CPAN packages (such as 'cpan' on
Strawberry Perl for Windows), no other tools or manually-installed prereqs are
needed (worst case, you can unpack the `.tar.gz` file and copy files into
place yourself!). Currently there are no compiles and links (Perl extensions)
done during the install process, only copying of .pm Perl module files. 

A package installer such as "cpan" (included with Strawberry Perl and some
other systems) can retrieve the package, unpack and copy files, and run 
installation tests without manual intervention. Not only PDF::Builder itself, 
but any needed prerequisites, may be quickly installed in this manner. Some 
Perl distributions (e.g., ActiveState) may repackage PDF::Builder and 
prerequisites into their own install format, as may Linux distributions such
as Red Hat or SUSE. Finally, it is possible to copy files directly from the 
GitHub repository to your system, and manually run the "t" (installation) 
tests, all without going through a `.tar.gz` CPAN package. There are many 
possibilities.

Note that there are several "optional" libraries (Perl modules) used to extend
and improve PDF::Builder. Read about the list of optional libraries in
PDF::Builder::Docs, and decide whether or not you want to install any of them.
By default, **none** are installed.

## Requirements

### Perl

**Perl 5.28** or higher. It will likely run on somewhat earlier versions, but
the CPAN installer may refuse to install it. The reason this version was
chosen was so that LTS (Long Term Support) versions of Perl going back about
6 years are officially supported (by PDF::Builder), and older versions are not
supported. The intent is to not waste time and effort trying to fix bugs which
are an artifact of old Perl releases. 

Usually about once a year the minimum level is bumped up, but this depends on 
whether Strawberry releases the newest Perl level. As Strawberry Perl releases 
new Perl levels, usually on an annual basis, we intend to bump up our required 
minimum Perl level (even-numbered production releases), to keep support for the 
last 6 calendar years of Perl releases, dropping older ones.

#### Older Perls

If you MUST install on an older (pre 5.28) Perl, you can try the following for
Strawberry Perl (Windows). NO PROMISES! Something similar MAY work for other
OS's and Perl installations:

1. Unpack installation file (`.tar.gz`, via a utility such as 7-Zip) into a directory, and cd to that directory
1. Edit META.json and change 5.028000 to 5.016000 or whatever level desired
1. Edit META.yml and change 5.028000 to 5.016000 or whatever level desired
1. Edit Makefile.PL and change `use 5.028000;` to `use 5.016000;`, change `$PERL_version` from `5.028000` to `5.016000`
1. `cpan .`

Note that some Perl installers MAY have a means to override or suppress the
Perl version check. That may be easier to use. Or, you may have to repack the
edited directory back into a `.tar.gz` installable. YMMV.

If all goes well, PDF::Builder will be installed on your system. Whether or
not it will RUN is another matter. Please do NOT open a bug report (ticket)
unless you're absolutely sure that the problem is not a result of using an old
Perl release, e.g., PDF::Builder is using a feature introduced in Perl 5.022
and you're trying to run Perl 5.012!

### Libraries used

These libraries are available from CPAN.

#### REQUIRED

These libraries should be automatically installed...

* Compress::Zlib
* Font::TTF
* Test::Exception (needed only for installation tests)
* Test::Memory::Cycle (needed only for installation tests)

#### OPTIONAL

These libraries are _recommended_ for improved functionality and performance.
The default behavior is **not** to attempt to install them during PDF::Builder
installation, in order to speed up the testing process and not clutter up
matters, especially if an optional package fails to install. You can always
manually install them later, if you desire to make use of their added
functionality.

* Perl::Critic (1.150 or higher, need if running tools/1\_pc.pl)
* Graphics::TIFF (19 or higher, recommended if using TIFF image functions)
* Image::PNG::Libpng (0.57 or higher, recommended for enhanced PNG image function processing)
* HarfBuzz::Shaper (0.024 or higher, needed for Latin script ligatures and kerning, as well as for any complex script such as Arabic, Indic scripts, or Khmer)
* Text::Markdown (1.000031 or higher, needed if using 'md1' markup)
* HTML::TreeBuilder (5.07 or higher, needed if using 'html' or 'md1' markup)
* Pod::Simple::XHTML (3.45 or higher, needed if using buildDoc.pl utility to create HTML documentation)
* SVGPDF (0.087 or higher, needed if using SVG image functions)

If an optional package is needed for cetain extended functionality, but not
installed, sometimes PDF::Builder
will be able to fall back to built-in partial functionality (TIFF and PNG
images), but other times will fail. After installing the missing package, you
may wish to then run the t-test suite for that library to confirm that it is
properly running, as well as running the examples.

**Note** that some of these packages, in turn, make use of various open source
libraries (DLLs/shared libs) that you may need to hunt around for, and install
on your system before you can install a given package. That is, they may not
necessarily come with your Operating System or Perl installation. Some such
packages may try to use "Alien" to build such prereqs, if missing. Other
packages are "pure Perl" and should install without trouble.

#### Fixes needed to OPTIONAL packages

Sometimes fixes or patches are needed for optional prerequisites. See the file
**INFO/Prereq\_fixes.md** for a list of known issues.

### External utilities

t/tiff.t (install testing for TIFF support) makes use of GhostScript and 
ImageMagick (convert utility). You may need to install these in order to get
full testing (tests that need them will be skipped if they are not installed).
Note that it has been reported that some versions of Mac Perl systems have
a 'convert' utility that is missing the default Arial font, and thus will fail
(see ticket 223).

## Manually building

As is the usual practice with building such a package (from the command line),
the steps are:

1. perl Makefile.PL
1. make
1. make test
1. make install

If you have your system configured to run Perl for a .pl/.PL file, you may be
able to omit "perl" from the first command, which creates a Makefile. "make"
is the generic command to run (it feeds on the Makefile produced by
Makefile.PL), but your system may have it under a different name, such as
dmake, gmake (e.g., Strawberry Perl on Windows), or nmake.

PDF::Builder does not currently compile and link anything, so `gcc`, `g++`,
etc. will not be used. The build process merely copies .pm files into place,
and runs the "t" tests to confirm the proper installation.

## Copyright

This software is Copyright (c) 2017-2025 by Phil M. Perry.

Previous copyrights are held by others (Steve Simms, Alfred Reibenschuh, 
et al.). See The HISTORY section of the documentation for more information.

We would like to acknowledge the efforts and contributions of a number of
users of PDF::Builder (and its predecessor, PDF::API2), who have given their
time to report issues, ask for new features, and have even contributed code.
Generally, you will find their names listed in the Changes and/or issue tickets
related to some particular item. See the **INFO/ACKNOWLEDGE.md** and
**INFO/SPONSORS** files.

## License

This is free software, licensed under:

`The GNU Lesser General Public License, Version 2.1, February 1999`

EXCEPT for some files which are explicitly under other, compatible, licenses
(the Perl License and the MIT License). You are permitted (at your option) to
redistribute and/or modify this software (those portions under LGPL) at an
LGPL version greater than 2.1. See INFO/LICENSE for more information on the
licenses and warranty statement.

### Carrying On...

PDF::Builder is Open Source software, built upon the efforts not only of the
current maintainer, but also of many people before me. Therefore, it's perfectly
fair to make use of the algorithms and even code (within the terms of the
LICENSE). That's exactly how the State of the
Art progresses! Just please be considerate and acknowledge the work of others
that you are building on, as well as pointing back to this package. Drop us a
note with news of your project (if based on the code and algorithms in
PDF::Builder, or even just heavily inspired by it) and we'll be happy to make
a pointer to _your_ work. The more cross-pollination, the better!

## See Also

* INFO/SUPPORT file for information on reporting bugs, etc. via GitHub Issues
* INFO/DEPRECATED file for information on deprecated features
* INFO/KNOWN\_INCOMP file for known incompatibilities with PDF::API2
* INFO/Prereq\_fixes.md possible patches for prerequisites
* CONTRIBUTING file for how to contribute to the project
* LICENSE file for more on the license term
* INFO/RoadMap file for the PDF::Builder road map
* INFO/ACKNOWLEDGE.md for "thank yous" to those who contributed to this product
* INFO/CONVERSION file for how to convert from PDF::API2 to PDF::Builder
* INFO/Changes\* files for older change logs
* INFO/PATENTS file for information on patents

`INFO/old/` also has some build and test tool files that are not currently used.

## Documentation

To build the full HTML documentation (all the POD), get the full installation
and go to the `docs/` directory. Run `buildDoc.pl --all` to generate the full
tree of documentation. There's a lot of additional information in the
PDF::Builder::Docs module (it's all documentation).

You may find it more convenient to point your browser to our
[Home Page](https://www.catskilltech.com/FreeSW/product/PDF-Builder/title/PDF%3A%3ABuilder/freeSW_full)
to see the full documentation build (as well as most of the example outputs).

We admit that the documentation is a bit light on "how to" task orientation.
We hope to more fully address this in the future, but for now, get the full
installation and look at the `examples/` and `contrib/` directories for sample
code that may help you figure out how to do things. The installation tests in
the `t/` and `xt/` directories might also be useful to you.

### A Note on Paper Sizes

Per PDF specifications, the default paper (media) size set in PDF::Builder
is 'US Letter' (8.5in x 11in, 216mm x 279mm). If you're in the civilized world,
and don't measure things in "bananas",
you may wish to specify 'A4' instead, in the `$pdf->mediabox('A4');` call.
Note that A4 is narrower and taller than Letter. If you want to ensure that
your output will be printable around the world, consider using the _universal_
paper size: `$pdf->mediabox('universal');`.
This will result in some wasted
space at the top of a printed A4 page, or some wasted right margin on a printed
Letter page, but it's better than having content cut off! It may also be
satisfactory to leave sufficient _margins_ around document content on standard
US Letter _or_ A4 media, with the following **minimum** margins (allowing
3mm/.125" for paper handling, plus extra for media size differences):
```
bottom: 3mm = .125" = 9pt  (bottom same for all media)
left:   3mm = .125" = 9pt  (left same for all media)

A4 top:     21mm = .83" = 60pt (A4 taller than Letter) 
Letter top: 3mm = .125" = 9pt

Letter right:  9mm = .375" = 27pt (Letter wider than A4)
A4 right:      3mm = .125" = 9pt
```
Please see the discussion on `mediabox()` and other "box" calls, about how
much of a page can actually be _printed_ on, allowing for pinch rollers and
other paper transport mechanisms. The above suggested margins assume, in
addition to Letter paper being .25" wider and .7" shorter than A4, that 1/8"
(9pt, 3mm) of paper is unprintable around the edges; your printer may vary.
