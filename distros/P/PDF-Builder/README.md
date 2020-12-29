# PDF::Builder

`A Perl library to facilitate the creation and modification of PDF files`

This archive contains the distribution PDF::Builder.
See **Changes** file for the version.

## Obtaining the Package

The installable Perl package may be obtained from
"https://metacpan.org/pod/PDF::Builder", or via a CPAN installer package. If
you install this product, only the run-time modules will be installed. Download
the full `.tar.gz` file and unpack it (hint: on Windows,
**7-Zip File Manager** is an excellent tool) to get utilities, test buckets,
example usage, etc.

Alternatively, you can obtain the full source files from
"https://github.com/PhilterPaper/Perl-PDF-Builder", where the ticket list
(bugs, enhancement requests, etc.) is also kept. Unlike the installable CPAN
version, this will have to be manually installed (copy files; there are no XS
compiles at this time).

Note that there are several "optional" libraries (Perl modules) used to extend
and improve PDF::Builder. Read about the list of optional libraries in
PDF::Builder::Docs, and decide whether or not you want to install any of them.

## Requirements

### Perl

**Perl 5.20** or higher. It will likely run on somewhat earlier versions, but
the CPAN installer may refuse to install it. The reason this version was
chosen was so that LTS (Long Term Support) versions of Perl going back about
6 years are officially supported (by PDF::Builder), and older versions are not
supported. The intent is to not waste time and effort trying to fix bugs which
are an artifact of old Perl releases.

#### Older Perls

If you MUST install on an older (pre 5.20) Perl, you can try the following for
Strawberry Perl (Windows). NO PROMISES! Something similar MAY work for other
OS's and Perl installations:

1. Unpack installation file (`.tar.gz`, via a utility such as 7-Zip) into a directory, and cd to that directory
1. Edit .perl-version and change 5.20.0 to 5.16.0 or whatever level desired
1. Edit Makefile.PL and change `use 5.020000;` to `use 5.016000;`, change `$PERL_version` from `5.020000` to `5.016000`
1. `cpan .`

Note that some Perl installers MAY have a means to override or suppress the
Perl version check. That may be easier to use. Or, you may have to repack the
edited directory back into a `.tar.gz` installable. YMMV.

If all goes well, PDF::Builder will be installed on your system. Whether or
not it will RUN is another matter. Please do NOT open a bug report (ticket)
unless you're absolutely sure that the problem is not a result of using an old
Perl release, e.g., PDF::Builder is using a feature introduced in Perl 5.008
and you're trying to run Perl 5.002!

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
The default behavior is to attempt to install all of them during PDF::Builder
installation. If you tell Makefile.PL (when prompted) _not_ to install any of
them, or they fail to install, you can always manually install them later.

* Graphics::TIFF (recommended if using TIFF image functions)
* Image::PNG::Libpng (recommended for enhanced PNG image function processing)
* HarfBuzz::Shaper (recommended for Latin script ligatures and kerning, as well as for any complex script such as Arabic, Indic scripts, or Khmer)

Other than an installer for standard CPAN packages (such as 'cpan' on
Strawberry Perl for Windows), no other tools or manually-installed prereqs are
needed (worst case, you can unpack the `.tar.gz` file and copy files into
place yourself!). Currently there are no compiles and links (Perl extensions)
done during the install process, only copying of .pm Perl module files.

## Copyright

This software is Copyright (c) 2017-2020 by Phil M. Perry.

Previous copyrights are held by others (Steve Simms, Alfred Reibenschuh, et al.).

## License

This is free software, licensed under:

`The GNU Lesser General Public License, Version 2.1, February 1999`

EXCEPT for some files which are explicitly under other licenses. You are
permitted (at your option) to redistribute and/or modify this software (those
portions under LGPL) at an LGPL version greater than 2.1. See INFO/LICENSE for
more information on the licenses and warranty statement.

## See Also

* INFO/RoadMap file for the PDF::Builder road map
* CONTRIBUTING file for how to contribute to the project
* INFO/SUPPORT file for information on reporting bugs, etc. via GitHub Issues (preferred), or the author's website
* INFO/DEPRECATED file for information on deprecated features
* INFO/KNOWN\_INCOMP file for known incompatibilities with PDF::API2
* INFO/Changes\* files for older change logs
* INFO/PATENTS file for information on patents
* INFO/CONVERSION file for how to convert from PDF::API2 to PDF::Builder

`INFO/old/` also has some build and test tool files that are not currently used.

## Documentation

To build the full HTML documentation (all the POD), get the full installation
and go to the `docs/` directory. Run `buildDoc.pl --all` to generate the full
tree of documentation. There's a lot of additional information in the
PDF::Builder::Docs module (it's all documentation).

We admit that the documentation is a bit light on "how to" task orientation.
We hope to more fully address this in the future, but for now, get the full
installation and look at the `examples/` and `contrib/` directories for sample
code that may help you figure out how to do things. The installation tests in
the `t/` directory might also be useful to you.
