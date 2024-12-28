## File: PDL::CCS.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: top-level PDL::CCS (also pulls in compatibility code)

package PDL::CCS;
use PDL;
use PDL::CCS::Config;
use PDL::CCS::Compat;
use PDL::CCS::Functions;
use PDL::CCS::Utils;
use PDL::CCS::Ufunc;
use PDL::CCS::Ops;
use PDL::CCS::MatrixOps;
use PDL::CCS::Nd;
use PDL::CCS::IO::FastRaw;
use strict;

our $VERSION = '1.23.29'; ##-- update with perl-reversion from Perl::Version module
our @ISA = ('PDL::Exporter');
our @EXPORT_OK =
  (
   @PDL::CCS::Config::EXPORT_OK,
   @PDL::CCS::Compat::EXPORT_OK,
   @PDL::CCS::Functions::EXPORT_OK,
   @PDL::CCS::Utils::EXPORT_OK,
   @PDL::CCS::Ufunc::EXPORT_OK,
   @PDL::CCS::Ops::EXPORT_OK,
   @PDL::CCS::MatrixOps::EXPORT_OK,
   @PDL::CCS::Nd::EXPORT_OK,
   @PDL::CCS::IO::FastRaw::EXPORT_OK,
  );
our %EXPORT_TAGS =
  (
   Func => [
	    @{$PDL::CCS::Config::EXPORT_TAGS{Func}},
	    @{$PDL::CCS::Compat::EXPORT_TAGS{Func}},
	    @{$PDL::CCS::Functions::EXPORT_TAGS{Func}},
	    @{$PDL::CCS::Utils::EXPORT_TAGS{Func}},
	    @{$PDL::CCS::Ufunc::EXPORT_TAGS{Func}},
	    @{$PDL::CCS::Ops::EXPORT_TAGS{Func}},
	    @{$PDL::CCS::MatrixOps::EXPORT_TAGS{Func}},
	    @{$PDL::CCS::Nd::EXPORT_TAGS{Func}},
	    @{$PDL::CCS::IO::FastRaw::EXPORT_TAGS{Func}},
	   ],               ##-- respect PDL conventions (hopefully)
  );
our @EXPORT = @{$EXPORT_TAGS{Func}};


1; ##-- make perl happy

##======================================================================
## pod: headers
=pod

=head1 NAME

PDL::CCS - Sparse N-dimensional PDLs with compressed column storage

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS;

 ## ... stuff happens ...

=cut

##======================================================================
## DESCRIPTION
##======================================================================
=pod

=head1 DESCRIPTION

PDL::CCS is now just a wrapper package which pulls in a number of
submodules.  See the documentation of the respective modules for details.

=cut

##======================================================================
## Submodules
##======================================================================
=pod

=head2 Modules

=over 4

=item L<PDL::CCS::Nd|PDL::CCS::Nd>

Perl class for representing large sparse N-dimensional numeric structures
using sorted index vector-vectors and a flat vector of non-missing values.
Supports a subset of the perl-side PDL API.

=item L<PDL::CCS::Compat|PDL::CCS::Compat>

Backwards-compatibility module for Harwell-Boeing compressed row- or column-storage.

=item L<PDL::CCS::Functions|PDL::CCS::Functions>

Some useful generic pure-perl functions for dealing directly with
CCS-, CRS-, and index-encoded PDLs.

=item L<PDL::CCS::Utils|PDL::CCS::Utils>

Low-level generic PDL::PP utilities for Harwell-Boeing encoding and decoding
"pointers" along arbitrary dimensions of a sparse PDL given an index list.

=item L<PDL::CCS::Ops|PDL::CCS::Ops>

Low-level generic PDL::PP utilities for blockwise alignment of pairs
of sparse index-encoded PDLs, useful for implementing binary operations.

=item L<PDL::CCS::Ufunc|PDL::CCS::Ufunc>

Various low-level ufunc (accumulator) utilities for index-encoded PDLs.

=item L<PDL::CCS::MatrixOps|PDL::CCS::MatrixOps>

Low-level generic PDL::PP utilities for matrix operations
on index-encoded PDLs.

=item L<PDL::CCS::IO::FastRaw|PDL::CCS::IO::FastRaw>

PDL::IO::FastRaw wrappers for PDL::CCS::Nd objects.

=back

=cut


##======================================================================
## Footer Administrivia
##======================================================================

##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

Original inspiration and algorithms from the SVDLIBC C library by Douglas Rohde;
which is itself based on SVDPACKC
by Michael Berry, Theresa Do, Gavin O'Brien, Vijay Krishna and Sowmini Varadhan.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

=over 4

=item *

PDL::CCS::Nd supports only a subset of the PDL API
(i.e. is not really a PDL).

=item *

Binary operations via alignment only work correctly when
missing values are annihilators.

=item *

Misleading module name: PDL::CCS::Nd objects actually use a native COO (full coordinate list)
format rather than CRS (compressed row storage) or CCS (compressed column storage);
see L<https://en.wikipedia.org/wiki/Sparse_matrix#Coordinate_list_(COO)> for a discussion.

=back

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

Copyright (C) 2005-2024 by Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1),
PDL(3perl),
PDL::CCS::Nd(3perl),
PDL::SVDLIBC(3perl),
L<https://en.wikipedia.org/wiki/Sparse_matrix>.

=cut
