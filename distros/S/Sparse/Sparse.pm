package Sparse;

use 5.008;
use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA = qw(Exporter);

%EXPORT_TAGS = ();

@EXPORT_OK = ();

@EXPORT = ();

our $VERSION = '0.03';

1;
__END__


=head1 NAME

Sparse - Perl module for Sparse Vectors 

=head1 SYNOPSIS

  use Sparse::Vector;

  # creating an empty sparse vector object
  $spvec=Sparse::Vector->new;

  # sets the value at index 12 to 5
  $spvec->set(12,5);

  # returns value at index 12
  $value = $spvec->get(12);

  # returns the indices of non-zero values in sorted order
  @indices = $spvec->keys;

  # returns 1 if the vector is empty and has no keys
  if($spvec->isnull)
  {
        print "vector is null.\n";
  }
  else
  {
        print "vector is not null.\n";
  }

  # print sparse vector to stdout
  $spvec->print;

  # returns the string form of sparse vector
  # same as print except the string is returned
  # rather than displaying on stdout
  $spvec->stringify;

  # adds sparse vectors v1, v2 and stores
  # result into v1
  $v1->add($v2);

  # adds binary equivalent of v2 to v1
  $v1->binadd($v2);
  # binary equivalnet treats all non-zero values
  # as 1s

  # increments the value at index 12
  $spvec->incr(12);

  # divides each vector entry by a given divisor 4
  $spvec->div(4);

  # returns norm of the vector
  $spvec_norm = $spvec->norm;

  # normalizes a sparse vector
  $spvec->normalize;

  # returns dot product of the 2 vectors
  $dotprod = $v1->dot($v2);

  # deallocates all entries
  $spvec->free;

=head1 ABSTRACT

Sparse::Vector is a Perl module that implements basic vector operations on
sparse vectors.

=head1 AUTHOR

Amruta D Purandare, <pura0010@d.umn.edu> 

Ted Pedersen, <tpederse@d.umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004,

Amruta Purandare, University of Minnesota, Duluth.
pura0010@umn.edu

Ted Pedersen, University of Minnesota, Duluth.
tpederse@umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut
