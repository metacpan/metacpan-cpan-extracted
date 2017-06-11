## File: PDL::CCS::IO::PETSc.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: LDA-C wrappers for PDL::CCS::Nd

package PDL::CCS::IO::PETSc;
use PDL::CCS::Version;
use PDL::CCS::Config qw(ccs_indx);
use PDL::CCS::Nd;
use PDL::CCS::IO::Common qw(:intern); ##-- for e.g. _ccsio_open(), _ccsio_close()
use PDL;
use Fcntl qw(:seek);	   ##-- for rewinding
use Carp qw(confess);
use strict;

our $VERSION = '1.23.4';
our @ISA = ('PDL::Exporter');
our @EXPORT_OK =
  (
   qw(ccs_wpetsc ccs_rpetsc),
  );
our %EXPORT_TAGS =
  (
   Func => [@EXPORT_OK],               ##-- respect PDL conventions (hopefully)
  );

our $PETSC_ASCII_HEADER = "Matrix Object: 1 MPI processes\n  type: seqaij\n";

##======================================================================
## pod: headers
=pod

=head1 NAME

PDL::CCS::IO::PETSc - PETSc-compatible I/O for PDL::CCS::Nd

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Nd;
 use PDL::CCS::IO::PETSc;

 ##-- sparse 2d matrix
 $ccs = PDL::CCS::Nd->newFromWhich($which,$nzvals);
 
 ccs_wpetsc($ccs,"ccs.petsc");      # write a sparse binary PETSc file
 $ccs2 = ccs_rpetsc("ccs.petsc");   # read a sparse binary PETSc file

=cut


##======================================================================
## I/O Utilities
=pod

=head1 I/O Utilities

=cut

##---------------------------------------------------------------
## ccs_wpetsc
=pod

=head2 ccs_wpetsc

Write a 2d L<PDL::CCS::Nd|PDL::CCS::Nd> matrix in PETSc sparse binary format.

 ccs_wpetsc($ccs,$filename_or_fh)
 ccs_wpetsc($ccs,$filename_or_fh,\%opts)

Options %opts:

 class_id  => $int,   ##-- PETSc MAT_FILE_CLASSID (default=1211216; see petsc/include/petscmat.h)
 pack_int  => $pack,  ##-- pack template for PETSc integers (default='N')
 pack_val  => $pack,  ##-- pack template for PETSc values (default='d>')
 ioblock   => $size,  ##-- I/O block size (default=8192)

=cut

*PDL::ccs_wpetsc = *PDL::CCS::Nd::wpetsc = \&ccs_wpetsc;
sub ccs_wpetsc {
  my ($ccs,$file,$opts) = @_;
  my %opts = %{$opts||{}};
  my $class_id = $opts{class_id} // 1211216;
  my $pack_int = $opts{pack_int} // 'N';
  my $pack_val = $opts{pack_val} // 'd>';
  my $ioblock  = $opts{ioblock}  || 8192;

  ##-- sanity check(s)
  confess("ccs_wpetsc(): input matrix must be physically indexed 2d!")
    if ($ccs->pdims->nelem != 2 || !$ccs->is_physically_indexed);

  ##-- open output file
  my $fh = _ccsio_open($file,'>')
    or confess("ccs_wpetsc(): open failed for output file '$file': $!");
  binmode($fh,':raw');
  local $,='';

  ##-- write output data: header
  # + Format (see file:///usr/share/doc/petsc3.4.2-doc/docs/manualpages/Mat/MatLoad.html#MatLoad)
  #     int    MAT_FILE_CLASSID
  #     int    number of rows
  #     int    number of columns
  #     int    total number of nonzeros
  #     int    *number nonzeros in each row
  #     int    *column indices of all nonzeros (starting index is zero)
  #     PetscScalar *values of all nonzeros
  my ($m,$n,$nnz) = ($ccs->pdims->list,$ccs->_nnz_p);
  $fh->print(pack("($pack_int)[4]", $class_id, $m,$n,$nnz));

  ##-- compute row-lengths
  my $ptr  = $ccs->ptr(0);
  my $plen = $ptr->slice("1:-1") - $ptr->slice("0:-2");

  ###-- write output data: ptr lens
  my ($i,$j);
  for ($i=0; $i < $m; $i = $j+1) {
    $j = $i+$ioblock;
    $j = $m-1 if ($j >= $m);
    $fh->print(pack("($pack_int)*", $plen->slice("$i:$j")->list));
  }
  undef $plen;
  undef $ptr;

  ##-- write output data: colids
  my $ix = $ccs->_whichND;
  for ($i=0; $i < $nnz; $i = $j+1) {
    $j = $i+$ioblock;
    $j = $nnz-1 if ($j >= $nnz);
    $fh->print(pack("($pack_int)*", $ix->slice("(1),$i:$j")->list));
  }

  ##-- write output data: nzvals
  my $nz = $ccs->_nzvals;
  for ($i=0; $i < $nnz; $i = $j+1) {
    $j = $i+$ioblock;
    $j = $nnz-1 if ($j >= $nnz);
    $fh->print(pack("($pack_val)*", $nz->slice("$i:$j")->list));
  }

  ##-- cleanup
  _ccsio_close($file,$fh)
    or confess("ccs_wpetsc(): close failed for output file '$file': $!");

  return 1;
}


##---------------------------------------------------------------
## ccs_rpetsc
=pod

=head2 ccs_rpetsc

REad a 2d L<PDL::CCS::Nd|PDL::CCS::Nd> matrix from PETSc sparse binary format.

 $ccs = ccs_rpetsc($filename_or_fh)
 $ccs = ccs_rpetsc($filename_or_fh,\%opts)

Options %opts:

 pack_int  => $pack,  ##-- pack template for PETSc integers (default='N')
 pack_val  => $pack,  ##-- pack template for PETSc values (default='d>')
 ioblock   => $size,  ##-- I/O block size (default=8192)
 type      => $type,  ##-- value type to return (default: double)
 sorted    => $bool,  ##-- assume input is lexicographically sorted (only if not transposted; default=do)
 flags     => $flags, ##-- flags for new ccs object (default=$PDL::CCS::Nd::CCSND_FLAGS_DEFAULT)

=cut

*PDL::ccs_rpetsc = *PDL::CCS::Nd::rpetsc = \&ccs_rpetsc;
sub ccs_rpetsc {
  shift if (UNIVERSAL::isa($_[0],'PDL') || UNIVERSAL::isa($_[0],'PDL::CCS::Nd'));
  my ($file,$opts) = @_;
  my %opts = %{$opts||{}};
  my $pack_int = $opts{pack_int} // 'N';
  my $pack_val = $opts{pack_val} // 'd>';
  my $ioblock  = $opts{ioblock}  || 8192;
  my $type     = $opts{type};
  $type = PDL->can($type)->() if (defined($type) && !ref($type) && PDL->can($type));
  $type = double if (!ref($type));
  $opts{sorted} //= 1;
  $opts{flags}  //= $PDL::CCS::Nd::CCSND_FLAGS_DEFAULT;

  ##-- open input file
  my $fh = _ccsio_open($file,'<')
    or confess("ccs_rpetsc(): open failed for input file '$file': $!");
  binmode($fh,':raw');
  local $,='';
  use bytes;

  ##-- read input data: header
  # + Format (see file:///usr/share/doc/petsc3.4.2-doc/docs/manualpages/Mat/MatLoad.html#MatLoad)
  #     int    MAT_FILE_CLASSID
  #     int    number of rows
  #     int    number of columns
  #     int    total number of nonzeros
  my $ilen = length(pack($pack_int,0));
  my $buf;
  read($fh,$buf,$ilen*4)==($ilen*4)
    or confess("ccs_rpetsc(): failed to read ", $ilen*4, " bytes of header data from '$file': $!");
  my ($magic,$m,$n,$nnz) = unpack("($pack_int)[4]", $buf);

  ##-- read input data: row-lengths
  #     int    *number nonzeros in each row
  my $plen = zeroes(ccs_indx, $m);
  my ($i,$j,$blen,$tmp);
  for ($i=0; $i < $m; $i=$j+1) {
    $j = $i+$ioblock;
    $j = $m-1 if ($j >= $m);
    $blen = $ilen * (1+$j-$i);
    read($fh,$buf,$blen)==$blen
      or confess("ccs_rpetsc(): failed to read $blen bytes of length data from '$file': $!");
    ($tmp=$plen->slice("$i:$j")) .= pdl(ccs_indx, [unpack("($pack_int)*", $buf)]);
  }

  ##-- setup index pdl
  my $ix = zeroes(ccs_indx,2,$nnz);
  $plen->rld($plen->sequence, $ix->slice("(0),"));
  undef $plen;

  ##-- read input data: column-indices
  #     int    *column indices of all nonzeros (starting index is zero)
  for ($i=0; $i < $nnz; $i=$j+1) {
    $j = $i+$ioblock;
    $j = $nnz-1 if ($j >= $nnz);
    $blen = $ilen * (1+$j-$i);
    read($fh,$buf,$blen)==$blen
      or confess("ccs_rpetsc(): failed to read $blen bytes of column-index data from '$file': $!");
    ($tmp=$ix->slice("(1),$i:$j")) .= pdl(ccs_indx, [unpack("($pack_int)*", $buf)]);
  }

  ##-- read input data: nzvals
  #     PetscScalar *values of all nonzeros
  my $vlen = length(pack($pack_val,0));
  my $nz   = zeroes($type, $nnz+1);
  for ($i=0; $i < $nnz; $i = $j+1) {
    $j = $i+$ioblock;
    $j = $nnz-1 if ($j >= $nnz);
    $blen = $vlen * (1+$j-$i);
    read($fh,$buf,$blen)==$blen
      or confess("ccs_rpetsc(): failed to read $vlen bytes of nonzero-value data from '$file': $!");
    ($tmp=$nz->slice("$i:$j")) .= pdl($type, [unpack("($pack_val)*", $buf)]);
  }

  ##-- cleanup
  _ccsio_close($file,$fh)
    or confess("ccs_wpetsc(): close failed for output file '$file': $!");

  ##-- construct and return
  return PDL::CCS::Nd->newFromWhich($ix,$nz,
				    pdims=>[$m,$n],
				    flags=>$opts{flags},
				    sorted=>$opts{sorted},
				    steal=>1,
				   );
}


1; ##-- be happy

##======================================================================
## POD: footer
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

Copyright (C) 2015, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

L<perl>,
L<PDL>,
L<PDL::CCS::Nd>,
L<PDL::CCS::IO::FastRaw>,
L<PDL::CCS::IO::FITS>,
L<PDL::CCS::IO::MatrixMarket>,
L<PDL::CCS::IO::LDAC>,
the PETSc binary matrix format definition at L<http://www.mcs.anl.gov/petsc/petsc-current/docs/manualpages/Mat/MatLoad.html>,
the PETSc homepage at L<http://www.mcs.anl.gov/petsc/>.
...

=cut


1; ##-- make perl happy
