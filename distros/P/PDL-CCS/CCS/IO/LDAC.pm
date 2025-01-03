## File: PDL::CCS::IO::LDAC.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: LDA-C wrappers for PDL::CCS::Nd

package PDL::CCS::IO::LDAC;
use PDL::CCS::Version;
use PDL::CCS::Config qw(ccs_indx);
use PDL::CCS::Nd;
use PDL::CCS::IO::Common qw(:intern); ##-- for e.g. _ccsio_header_lines(), _ccsio_parse_header()
use PDL;
use PDL::IO::Misc;         ##-- for rcols(), wcols(), $PDL::IO::Misc::deftype
use Fcntl qw(:seek);       ##-- for rewinding
use Carp qw(confess);
use strict;

our $VERSION = '1.24.0';
our @ISA = ('PDL::Exporter');
our @EXPORT_OK =
  (
   qw(ccs_writeldac ccs_readldac),
  );
our %EXPORT_TAGS =
  (
   Func => [@EXPORT_OK],               ##-- respect PDL conventions (hopefully)
  );

##======================================================================
## pod: headers
=pod

=head1 NAME

PDL::CCS::IO::LDAC - LDA-C format text I/O for PDL::CCS::Nd

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Nd;
 use PDL::CCS::IO::LDAC;

 ##-- (Document x Term) matrix
 $dtm = PDL::CCS::Nd->newFromWhich($which,$nzvals);
 
 ccs_writeldac($dtm,"dtm.ldac");   # write a sparse LDA-C text file
 $dtm2 = ccs_readldac("dtm.ldac"); # read a sparse LDA-C text file

 ###-- (Term x Document) matrix in document-primary format
 $tdm = $dtm->xchg(0,1)->make_physically_indexed();
 
 ccs_writeldac($tdm,"tdm.ldac",   {transpose=>1});
 $dtm2 = ccs_readldac("tdm.ldac", {transpose=>1});

=cut


##======================================================================
## I/O utilities
=pod

=head1 I/O Utilities

=cut

##---------------------------------------------------------------
## ccs_writeldac
=pod

=head2 ccs_writeldac

Write a 2d L<PDL::CCS::Nd|PDL::CCS::Nd> (Document x Term)
matrix as an LDA-C text file.  If the C<transpose> option is specified and true,
the input matrix C<$ccs> is treated as as a (Term x Document) matrix,
and output lines correspond to logical dimension 1 of C<$ccs>.  Otherwise,
output lines correspond to logical dimension 0 of C<$ccs>, which is expected
to be a (Document x Term) matrix.

 ccs_writeldac($ccs,$filename_or_fh)
 ccs_writeldac($ccs,$filename_or_fh,\%opts)

Options %opts:

 header => $bool,     ##-- do/don't write a header to the output file (default=do)
 transpose => $bool,  ##-- treat input $ccs as (Term x Document) matrix (default=don't)

=cut

*PDL::ccs_writeldac = *PDL::CCS::Nd::writeldac = \&ccs_writeldac;
sub ccs_writeldac {
  my ($ccs,$file,$opts) = @_;
  my %opts = %{$opts||{}};
  $opts{header} = 1 if (!defined($opts{header}));

  ##-- sanity check(s)
  confess("ccs_writeldac(): input matrix must be physically indexed 2d!")
    if ($ccs->pdims->nelem != 2);

  ##-- open output file
  my $fh = _ccsio_open($file,'>')
    or confess("ccs_writeldac(): open failed for output file '$file': $!");
  #binmode($fh,':raw');
  local $,='';

  ##-- maybe print header
  if ($opts{header}) {
    print $fh
      ("%%LDA-C sparse matrix file; see http://www.cs.princeton.edu/~blei/lda-c/readme.txt\n",
       (map {("%", __PACKAGE__, " $_")} @{_ccsio_header_lines($ccs)}),
      );
  }

  ##-- transpose?
  my ($ddim,$tdim) = $opts{transpose} ? (1,0) : (0,1);

  ##-- convert to lda-c format: use ptr()
  my ($ptr,$pi2nzi) = $ccs->ptr($ddim);
  my $nd = $ptr->nelem-1;
  my $ix = $ccs->_whichND;
  my $nz = $ccs->_nzvals;
  my ($di,$i,$j,$nzi);
  for ($di=0; $di < $nd; ++$di) {
    ($i,$j) = ($ptr->at($di),$ptr->at($di+1));
    $nzi    = $pi2nzi->slice("$i:".($j-1));
    print $fh join(' ', ($j-$i), map {$ix->at($tdim,$_).":".$nz->at($_)} $nzi->list), "\n";
  }

  ##-- cleanup
  _ccsio_close($file,$fh)
    or confess("ccs_writeldac(): close failed for output file '$file': $!");

  return 1;
}


##---------------------------------------------------------------
## ccs_readldac
=pod

=head2 ccs_readldac

Read a 2d (Document x Term) matrix from an LDA-C text file as a
L<PDL::CCS::Nd|PDL::CCS::Nd> object.
If the C<transpose> option is specified and true,
the output matrix C<$ccs> will be a (Term x Document) matrix,
and input lines correspond to logical dimension 1 of C<$ccs>.  Otherwise,
input lines correspond to logical dimension 0 of C<$ccs>, which will be
returned as a (Document x Term) matrix.

 $ccs = ccs_readldac($filename_or_fh)
 $ccs = ccs_readldac($filename_or_fh,\%opts)

Options %opts:

 header => $bool,    ##-- do/don't try to read header data from the output file (default=do)
 type => $type,      ##-- value datatype (default: from header or $PDL::IO::Misc::deftype)
 transpose => $bool, ##-- generate a (Term x Document) matrix (default=don't)
 sorted => $bool,    ##-- assume input is lexicographically sorted (only if not transposed; default=don't)

=cut

*PDL::ccs_readldac = *PDL::CCS::Nd::readldac = \&ccs_readldac;
sub ccs_readldac {
  shift if (UNIVERSAL::isa($_[0],'PDL') || UNIVERSAL::isa($_[0],'PDL::CCS::Nd'));
  my ($file,$opts) = @_;
  my %opts = %{$opts||{}};
  $opts{header} = 1 if (!defined($opts{header}));

  ##-- open input file
  my $fh = _ccsio_open($file,'<')
    or confess("ccs_readldac(): open failed for input file '$file': $!");

  ##-- maybe scan for ccs header
  my $header;
  if ($opts{header}) {
    ##-- scan initial comments for CCS header
    my @hlines = qw();
    while (defined($_=<$fh>)) {
      chomp;
      if (/^[%\#](\S+) (.*)$/) {
        push(@hlines,$2) if (substr($_,1,length(__PACKAGE__)) eq __PACKAGE__);
      } elsif (!/^[%\#]/) {
        last;
      }
    }
    $header = _ccsio_parse_header(\@hlines);
  } else {
    $header = {};
  }

  ##-- get value datatype
  my $type = $opts{type} || $header->{iotype} || $PDL::IO::Misc::deftype;
  $type    = PDL->can($type)->() if (defined($type) && !ref($type) && PDL->can($type));
  $type    = $PDL::IO::Misc::deftype if (!ref($type));

  ##-- get nnz (per doc)
  seek($fh,0,SEEK_SET)
    or confess("ccs_readldac(): seek() failed for input file '$file': $!");
  my $nnz0 = PDL->rcols($fh, [0], { TYPES=>[ccs_indx()], IGNORE=>qr{^\s*[^0-9]} });
  my $nnz  = $nnz0->sum;
  my $nlines = $nnz0->nelem;
  undef($nnz0);

  ##-- allocate output pdls
  my $ix   = zeroes(ccs_indx(), 2,$nnz);
  my $nz   = zeroes($type, $nnz+1);

  ##-- process input
  seek($fh,0,SEEK_SET)
    or confess("ccs_readldac(): seek() failed for input file '$file': $!");
  my ($dim0,$dim1) = $opts{transpose} ? (1,0) : (0,1);
  my ($nzi,$i0,$i1,$f);
  for ($nzi=$i0=0; $i0 < $nlines && $nzi < $nnz && defined($_=<$fh>); ) {
    chomp;
    next if (/^\s*(?:$|[^0-9])/);
    while (/\b([0-9]+)\s*:\s*(\S+)/g) {
      ($i1,$f) = ($1,$2);
      $ix->set($dim1,$nzi => $i1);
      $ix->set($dim0,$nzi => $i0);
      $nz->set($nzi => $f);
      ++$nzi;
    }
    ++$i0;
  }

  ##-- cleanup
  _ccsio_close($file,$fh)
    or confess("ccs_readldac(): close failed for input file '$file': $!");

  ##-- guess header data
  if (!defined($header->{pdims})) {
    $header->{pdims} = [];
    $header->{pdims}[$dim0] = $nlines;
    $header->{pdims}[$dim1] = $ix->slice("($dim1),")->max+1;
  }
  $header->{flags} = $PDL::CCS::Nd::CCSND_FLAGS_DEFAULT if (!defined($header->{flags}));

  ##-- construct and return
  return PDL::CCS::Nd->newFromWhich($ix,$nz,
                                    pdims=>$header->{pdims},
                                    vdims=>$header->{vdims},
                                    flags=>$header->{flags},
                                    sorted=>($opts{sorted} && !$opts{transpose}),
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

LDA-C package by by David M. Blei.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

Copyright (C) 2015-2024, Bryan Jurish. All rights reserved.

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
the LDA-C package documentation at L<http://www.cs.princeton.edu/~blei/lda-c/>
...

=cut


1; ##-- make perl happy
