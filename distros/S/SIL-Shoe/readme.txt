                SIL Shoebox Utilities

This module kit consists of a number of Shoebox utilities. Particularly,
it includes:

    SH2XML      a discussion of converting Shoebox data to XML. See
                XML\Sh2XML.pdf
    Interlin    Tools for converting interlinear Shoebox databases to
                RTF for typesetting. See Interlin\Manual.pdf

INSTALLATION

Due to the number of Windows users without make, the installation
includes pmake. Thus to install, type the following sequence of
commands:

    perl Makefile.PL
    pmake install
    pmake realclean

(There is no test suite, for those users used to Perl modules. And yes,
make will work just as well).

And for those people who are really lazy, all you need do is to run:

    setup

which runs the above three commands for you.

INSTRUCTIONS

For instructions on the various utilities, read the appropriate .pdf
files as listed above. For a more involved discussion of installation
issues, read XML\Sh2XML.pdf

AUTHOR

martin_hosken@sil.org

