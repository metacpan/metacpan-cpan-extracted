## File: PDL::CCS::IO::MatrixMarket.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: MatrixMarket I/O wrappers for PDL::CCS::Nd

package PDL::CCS::IO::MatrixMarket;
use PDL::CCS::Version;
use PDL::CCS::Config qw(ccs_indx);
use PDL::CCS::Nd;
use PDL::CCS::IO::Common qw(:intern); ##-- for e.g. _ccsio_header_lines(), _ccsio_parse_header()
use PDL;
use PDL::IO::Misc;	   ##-- for rcols(), wcols(), $PDL::IO::Misc::deftype
use Fcntl qw(:seek);	   ##-- for rewinding
use Carp qw(confess);
use strict;

our $VERSION = '1.23.9';
our @ISA = ('PDL::Exporter');
our @EXPORT_OK =
  (
   qw(ccs_writemm ccs_readmm writemm readmm),
  );
our %EXPORT_TAGS =
  (
   Func => [@EXPORT_OK],               ##-- respect PDL conventions (hopefully)
  );

##-- matrix market magic header line, sparse
my $MMAGIC = '%%MatrixMarket matrix coordinate real general';

##-- matrix market magic header line, dense
my $DMAGIC = '%%MatrixMarket matrix array real general';

##======================================================================
## pod: headers
=pod

=head1 NAME

PDL::CCS::IO::MatrixMarket - Matrix Market Exchange Format text I/O for PDL::CCS::Nd

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Nd;
 use PDL::CCS::IO::MatrixMarket;

 $ccs = PDL::CCS::Nd->newFromWhich($which,$nzvals);

 ccs_writemm($ccs,"ccs.mm");	 # write a sparse matrix market text file
 $ccs2 = ccs_readmm("ccs.mm");   # read a sparse matrix market text file

 $dense = random(10,10);	 # ... also supported for dense piddles
 writemm($dense, "file.mm");	 # write a dense matrix market text file
 $dense2 = readmm("file.mm");	 # read a dense matrix market text file

=cut


##======================================================================
## I/O utilities
=pod

=head1 I/O Utilities

=cut

##---------------------------------------------------------------
## ccs_writemm
=pod

=head2 ccs_writemm

Write a L<PDL::CCS::Nd|PDL::CCS::Nd> object as a MatrixMarket sparse coordinate text file.

 ccs_writemm($ccs,$filename_or_fh)
 ccs_writemm($ccs,$filename_or_fh,\%opts)

Options %opts:

 start  => $i,      ##-- index of first element (like perl $[); default=1 for MatrixMarket compatibility
 header => $bool,   ##-- write embedded PDL::CCS::Nd header? (default=do)

=cut

*PDL::ccs_writemm = *PDL::CCS::Nd::writemm = \&ccs_writemm;
sub ccs_writemm {
  my ($ccs,$file,$opts) = @_;
  my %opts =%{$opts||{}};
  $opts{start} = 1 if (!defined($opts{start}));
  $opts{header} = 1 if (!defined($opts{header}));

  ##-- write MatrixMarket magic header
  my $fh = _ccsio_open($file,'>')
    or confess("ccs_writemm(): open failed for output file '$file': $!");
  #binmode($fh,':raw');
  local $,='';
  print $fh "$MMAGIC\n";

  ##-- write ccs header to output file
  if ($opts{header}) {
    print $fh map {("%", __PACKAGE__, " $_")} @{_ccsio_header_lines($ccs)};
  }

  ##-- write mm dimensions to output file
  print $fh join(' ', '',$ccs->pdims->list,$ccs->_nnz_p), "\n";

  ##-- write mm data to output file
  my $ix = $ccs->_whichND;
  $ix    = ($ix+$opts{start}) if ($opts{start} != 0);
  wcols($ix->xchg(0,1), $ccs->_nzvals, $fh)
    or confess("ccs_writemm(): failed to write data to '$file': $!");

  ##-- cleanup
  _ccsio_close($file,$fh)
    or confess("ccs_writemm(): close failed for output file '$file': $!");

  return 1;
}

##---------------------------------------------------------------
## writemm (dense)
=pod

=head2 writemm

Write a dense PDL as a MatrixMarket array text file.

 writemm($pdl,$filename_or_handle)
 writemm($pdl,$filename_or_handle,\%opts)

Options %opts: (none yet)

=cut

*PDL::writemm = \&writemm;
sub writemm {
  my ($pdl,$file,$opts) = @_;

  ##-- dispatch for PDL::CCS::Nd objects
  return ccs_writemm($pdl,$file,$opts) if (UNIVERSAL::isa($pdl,'PDL::CCS::Nd'));

  ##-- write MatrixMarket magic header
  my $fh = _ccsio_open($file,'>')
    or confess("writemm(): open failed for output file '$file': $!");
  #binmode($fh,':raw');
  local $,='';
  print $fh "$DMAGIC\n";

  ##-- print administrative data
  print $fh "%", __PACKAGE__, " type ", $pdl->type, "\n";

  ##-- write mm dimensions to output file
  print $fh " ", join(' ', $pdl->dims), "\n";

  ##-- write flat data to output file
  wcols($pdl->flat, $fh)
    or confess("writemm(): failed to write data to '$file': $!");

  ##-- cleanup
  _ccsio_close($file,$fh)
    or confess("writemm(): close failed for output file '$file': $!");

  return 1;
}


##---------------------------------------------------------------
## ccs_readmm
=pod

=head2 ccs_readmm

Read a Matrix Market sparse coordinate text file
as a L<PDL::CCS::Nd|PDL::CCS::Nd> object
using L<PDL::IO::Misc::rcols()|PDL::IO::Misc/rcols()>.

 $ccs = ccs_readmm($filename_or_fh)
 $ccs = ccs_readmm($filename_or_fh,\%opts)

Options %opts:

 start  => $i,      ##-- index of first element (like perl $[); default=1 for MatrixMarket compatibility
 header => $bool,   ##-- attempt to read embedded CCS header from file (default=do)
 sorted => $bool,   ##-- assume input data is sorted (default=0)
 nomagic => $bool,  ##-- don't check for matrix market magic header (default:do)

=cut

*PDL::ccs_readmm = *PDL::CCS::Nd::readmm = \&ccs_readmm;
sub ccs_readmm {
  shift if (UNIVERSAL::isa($_[0],'PDL') || UNIVERSAL::isa($_[0],'PDL::CCS::Nd'));
  my ($file,$opts) = @_;
  my %opts = %{$opts||{}};
  $opts{start} = 1 if (!defined($opts{start}));
  $opts{header} = 1 if (!defined($opts{header}));

  ##-- open input file
  my $fh = _ccsio_open($file,'<')
    or confess("ccs_readmm(): open failed for input file '$file': $!");

  ##-- get matrix market magic header
  if (!$opts{nomagic}) {
    my $mmagic = <$fh>; chomp($mmagic);
    if ($mmagic eq $DMAGIC) {
      ##-- dense input file, read as dense PDL
      _ccsio_close($file,$fh);
      return readmm($file,{%opts,nomagic=>1});
    }
    elsif ($mmagic ne $MMAGIC) {
      confess("ccs_readmm(): bad magic header line in input file, should be '$MMAGIC'");
    }
  }

  ##-- scan initial comments, extracting CCS header
  my @hlines = qw();
  while (defined($_=<$fh>)) {
    chomp;
    if (/^%(\S+) (.*)$/) {
      push(@hlines,$2) if ($opts{header} && substr($_,1,length(__PACKAGE__)) eq __PACKAGE__);
    } elsif (!/^%/) {
      last;
    }
  }
  ##-- parse embedded CCS header if requested
  my $header = _ccsio_parse_header($opts{header} ? \@hlines : []);

  ##-- we now have 1st non-comment line in $_: scan for mm dimension list
  while ($_ =~ /^\s*$/) {
    $_ = <$fh>;
    chomp;
  }
  my @dims = split(' ',$_);
  my $nnz  = pop(@dims);

  ##-- update ccs header if required
  my $mmdims = pdl(ccs_indx(),\@dims);
  if (defined($header->{pdims}) && ($header->{pdims}->nelem != $mmdims->nelem || !all($header->{pdims}==$mmdims))) {
    $header->{pdims} = $mmdims;
    $header->{vdims} = undef;
  }

  ##-- read data: indices
  my $offset = tell($fh);
  my $ix = PDL->rcols($fh, [0..$#dims], { IGNORE=>qr{^%}, TYPES=>[ccs_indx()] });
  $ix   -= $opts{start} if ($opts{start} != 0);
  $ix    = $ix->xchg(0,1);

  ##-- read data: values
  seek($fh,$offset,SEEK_SET)
    or confess("ccs_readmm(): seek() failed for input file '$file': $!");
  my $iotype = $header->{iotype};
  $iotype    = PDL->can($iotype)->() if (defined($iotype) && !ref($iotype) && PDL->can($iotype));
  $iotype    = $PDL::IO::Misc::deftype if (!ref($iotype));
  my $nz = PDL->rcols($fh, [$#dims+1],   { IGNORE=>qr{^%}, TYPES=>[$iotype] });
  $nz    = $nz->append(0); ##-- missing value

  ##-- cleanup
  _ccsio_close($file,$fh)
    or confess("ccs_readmm(): close failed for input file '$file': $!");

  ##-- construct and return
  return PDL::CCS::Nd->newFromWhich($ix,$nz,
				    pdims=>$header->{pdims},
				    vdims=>$header->{vdims},
				    flags=>$header->{flags},
				    sorted=>$opts{sorted},
				    steal=>1);
}


##---------------------------------------------------------------
## readmm (dense)
=pod

=head2 readmm

Read a Matrix Market dense array text file as a dense pdl using L<PDL::IO::Misc::rcols()|PDL::IO::Misc/rcols()>.

 $pdl = readmm($fname)
 $pdl = readmm($fname,\%opts)

Options %opts:

 nomagic => $bool,  ##-- don't check for matrix market magic header (default:do)

=cut

*PDL::readmm = \&readmm;
sub readmm {
  shift if (UNIVERSAL::isa($_[0],'PDL') || UNIVERSAL::isa($_[0],'PDL::CCS::Nd'));
  my ($file,$opts) = @_;
  my %opts = %{$opts||{}};

  ##-- open input file
  my $fh = _ccsio_open($file,'<')
    or confess("readmm(): open failed for input file '$file': $!");

  ##-- get matrix market magic header
  if (!$opts{nomagic}) {
    my $dmagic = <$fh>; chomp($dmagic);
    if ($dmagic eq $MMAGIC) {
      ##-- sparse input file, read as PDL::CCS::Nd
      _ccsio_close($file,$fh);
      return ccs_readmm($file,{%opts,nomagic=>1});
    }
    elsif ($dmagic ne $DMAGIC) {
      confess("readmm(): bad magic header line in input file, should be '$DMAGIC'")
    }
  }

  ##-- scan for header
  my $iotype = $PDL::IO::Misc::deftype;
  while (defined($_=<$fh>)) {
    if (!/^%/) {
      if (/^%(\S+) type (\S+)/ && $1 eq __PACKAGE__) {
	$iotype = PDL->can($_)->() if (PDL->can($_));
      }
    } elsif (!/^\s*$/) {
      next;
    }
    last;
  }
  ##-- parse dims
  my @dims = split(' ',$_);

  ##-- read data
  my $pdl = rcols($fh, [], { IGNORE=>qr{^%}, TYPES=>[$iotype] });

  ##-- cleanup
  _ccsio_close($file,$fh)
    or confess("ccs_readmm(): close failed for input file '$file': $!");

  ##-- construct and return
  #$pdl = $pdl->reshape(@dims); ##-- pdl v2.014 chokes on this
  my $out = zeroes($pdl->type, @dims);
  (my $tmp = $out->flat) .= $pdl->flat;
  return $out;
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

Copyright (C) 2015-2018, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

L<perl>,
L<PDL>,
L<PDL::CCS::Nd>,
L<PDL::CCS::IO::FastRaw>,
L<PDL::CCS::IO::FITS>,
L<PDL::CCS::IO::LDAC>,
the matrix market format documentation at L<http://math.nist.gov/MatrixMarket/formats.html>
...

=cut


1; ##-- make perl happy
