package SIL::Shoe;

$VERSION = 1.37;    # MJPH       
# $VERSION = 1.36;    # MJPH       1-MAR-2007     Add xml2sh
# $VERSION = 1.35;    # MJPH      18-SEP-2006     Add template sh2xml
# $VERSION = 1.34;    #   MJPH     1-SEP-2006     fix interlinear processing
# $VERSION = 1.33;    #   MJPH    24-AUG-2006     add sh2odt
# $VERSION = 1.32;    #   MJPH    30-JUN-2006     fix shlex index, add sh2sh -n
# $VERSION = 1.31;    #   MJPH    20-JUN-2006     add shlex, sh2csv, csv2sh

=head1 NAME

SIL::Shoe - Module for interacting with SIL Shoebox and SIL Toolbox files

=head1 DESCRIPTION

This module has support for SIL Shoebox and SIL Toolbox files that are stored
using Standard Format which is a textual format in which a field is marked by
a Standard Format Marker (SFM) at the start of a line. An SFM is simply \
followed by some non space characters.

A key field marker is used to mark the start of a record. Records may have
multiple key fields with the same contents and a field marker (other than
the key field marker) may occur multiple times within a record.

In addition to the core data, there are various settings files that facilitate
the database program itself. This module interacts with those as well.

Scripts that come with the module are key programs: cvs2sh, sh2cvs, sh2sh,
sh2xml, shadd, shdiff3, shdiffn, shed, shintr, shlex, sh_rtf, zipdiff,
zipmerge, zippatch
