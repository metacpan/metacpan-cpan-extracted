## File: PDL::CCS::IO::FastRaw.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: PDL::IO::FastRaw wrappers for PDL::CCS::Nd

package PDL::CCS::IO::FastRaw;
use PDL::CCS::Version;
use PDL::CCS::Config qw(ccs_indx);
use PDL::CCS::Nd;
use PDL::CCS::IO::Common qw(:intern);
use PDL;
use PDL::IO::FastRaw;
use Carp qw(confess);
use strict;

our $VERSION = '1.23.18';
our @ISA = ('PDL::Exporter');
our @EXPORT_OK = qw(ccs_writefraw ccs_readfraw ccs_mapfraw);
our %EXPORT_TAGS =
  (
   Func => [@EXPORT_OK],               ##-- respect PDL conventions (hopefully)
  );



##======================================================================
## pod: headers
=pod

=head1 NAME

PDL::CCS::IO::FastRaw - PDL::IO::FastRaw wrappers for PDL::CCS::Nd

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Nd;
 use PDL::CCS::IO::FastRaw;

 $ccs = PDL::CCS::Nd->newFromWhich($which,$nzvals);

 ccs_writefraw($ccs,$fname);	 # write a pair of raw files
 $ccs2 = ccs_readfraw($fname);   # read a pair of raw files

 $ccs3 = ccs_mapfraw($fname,{ReadOnly=>1}); # mmap a pair of files, don't read yet

=cut

##======================================================================
## I/O utilities
=pod

=head1 I/O Utilities

=cut

##---------------------------------------------------------------
## ccs_writefraw
=pod

=head2 ccs_writefraw

Write a pair of raw binary files using PDL::IO::FastRaw::writefraw().

 ccs_writefraw($ccs,$fname)
 ccs_writefraw($ccs,$fname,\%opts)

Options %opts:

 Header      => $Header,       ##-- default="$fname.hdr"
 ixFile      => $ixFile,       ##-- default="$fname.ix"
 ixHeader    => $ixHeader,     ##-- default="$ixFile.hdr"
 nzFile      => $nzFile,       ##-- default="$fname.nz"
 nzHeader    => $nzHeader,     ##-- default="$nzFile.hdr"

=cut

*PDL::ccs_writefraw = *PDL::CCS::Nd::writefraw = \&ccs_writefraw;
sub ccs_writefraw {
  my ($ccs,$fname,$opts) = @_;

  ##-- get filenames
  my $hFile  = $opts->{Header} // "$fname.hdr";
  my $ixFile = $opts->{ixFile} // "$fname.ix";
  my $nzFile = $opts->{nzFile} // "$fname.nz";

  ##-- write header
  _ccsio_write_header($ccs, $hFile)
    or confess("ccs_writefraw(): failed to write header-file $hFile: $!");

  ##-- write pdls
  PDL::writefraw($ccs->_whichND, $ixFile, _ccsio_opts_ix($opts))
      or confess("ccs_writefraw(): failed to write index-file $ixFile: $!");
  PDL::writefraw($ccs->_vals,  $nzFile, _ccsio_opts_nz($opts))
      or confess("ccs_writefraw(): failed to write values-file $nzFile: $!");

  return 1;
}


##---------------------------------------------------------------
## ccs_readfraw
=pod

=head2 ccs_readfraw

Read a pair of raw binary files using PDL::IO::FastRaw::readfraw().

 $ccs = ccs_readfraw($fname)
 $ccs = ccs_readfraw($fname,\%opts)

Options %opts:

 Header   => $Header,      ##-- default="$fname.hdr"
 ixFile   => $ixFile,      ##-- default="$fname.ix"
 ixHeader => $ixHeader,    ##-- default="$ixFile.hdr"
 nzFile   => $nzFile,      ##-- default="$fname.nz"
 nzHeader => $nzHeader,    ##-- default="$nzFile.hdr"
 sorted   => $bool,        ##-- is data on disk already sorted? (default=1)

=cut

*PDL::ccs_readfraw = *PDL::CCS::Nd::readfraw = \&ccs_readfraw;
sub ccs_readfraw {
  shift if (UNIVERSAL::isa($_[0],'PDL') || UNIVERSAL::isa($_[0],'PDL::CCS::Nd'));
  my ($file,$opts) = @_;

  ##-- get filenames
  my $hFile  = $opts->{Header} // "$file.hdr";
  my $ixFile = $opts->{ixFile} // "$file.ix";
  my $nzFile = $opts->{nzFile} // "$file.nz";

  ##-- read header
  my $header = _ccsio_read_header($hFile)
    or confess("ccs_readfraw(): failed to read header-file $hFile: $!");

  ##-- read pdls
  defined(my $ix = PDL->readfraw($ixFile, _ccsio_opts_ix($opts)))
    or confess("ccs_readfraw(): failed to read index-file $ixFile: $!");
  defined(my $nz = PDL->readfraw($nzFile, _ccsio_opts_nz($opts)))
    or confess("ccs_readfraw(): failed to read values-file $nzFile: $!");

  ##-- construct and return
  return PDL::CCS::Nd->newFromWhich($ix,$nz,
				    pdims=>$header->{pdims},
				    vdims=>$header->{vdims},
				    flags=>$header->{flags},
				    sorted=>($opts->{sorted}//1),
				    steal=>1);
}


##---------------------------------------------------------------
## ccs_mapfraw
=pod

=head2 ccs_mapfraw

Read a pair of raw binary files using PDL::IO::FastRaw::readfraw().

 $ccs = ccs_mapfraw($fname)
 $ccs = ccs_mapfraw($fname,\%opts)

Global options in %opts:

 Header    => $Header,   ##-- default="$fname.hdr"
 ReadOnly  => $bool,     ##-- read-only mode?
 Dims      => \@dims,    ##-- logical dimensions (~ \@pdims)
 Datatype  => $type,     ##-- CCS::Nd datatype
 Creat     => $bool,     ##-- create file(s)?
 Trunc     => $bool,     ##-- truncate file(s)?

CCS::Nd options in %opts:

 flags     => $flags,    ##-- CCS::Nd flags
 nnz       => $nnz,      ##-- CCS::Nd nnz
 pdims     => \@pdims,   ##-- CCS::Nd physical dimensions
 vdims     => \@vdims,   ##-- CCS::Nd virtual dimensions
 sorted    => $bool,     ##-- is data on disk sorted? (default=1)

Component options in %opts, for ${c} in qw(ix nz):

 "${c}${opt}" => $cValue,   ##-- override global option ${opt}
 "${c}File"   => $cFile,    ##-- default="$fname.${c}"
 "${c}Header" => $cHeader,  ##-- default="$cFile.hdr"

=cut

*PDL::ccs_mapfraw = *PDL::CCS::Nd::mapfraw = \&ccs_mapfraw;
sub ccs_mapfraw {
  shift if (UNIVERSAL::isa($_[0],'PDL') || UNIVERSAL::isa($_[0],'PDL::CCS::Nd'));
  my ($file,$opts) = @_;

  ##-- get filenames
  my $hFile  = $opts->{Header} // "$file.hdr";
  my $ixFile = $opts->{ixFile} // "$file.ix";
  my $nzFile = $opts->{nzFile} // "$file.nz";

  ##-- get ccs header
  my $header = {
		pdims => ($opts->{pdims} // $opts->{Dims}),
		vdims => $opts->{vdims},
		flags => ($opts->{flags} // $PDL::CCS::Nd::CCSND_FLAGS_DEFAULT),
	       };
  if (!defined($header->{pdims})) {
    my $hdr = _ccsio_read_header($hFile)
      or confess("ccs_mapfraw(): failed to read header-file $hFile: $!");
    $header->{$_} //= $hdr->{$_} foreach (keys %$hdr);
  }
  $header->{pdims} = PDL->topdl(ccs_indx(),$header->{pdims}) if (!ref($header->{pdims}));
  $header->{vdims} = $header->{pdims}->sequence if (!defined($header->{vdims}));
  $header->{vdims} = PDL->topdl(ccs_indx(),$header->{vdims}) if (!ref($header->{vdims}));

  ##-- get component options
  my %defaults = (map {($_=>$opts->{$_})} grep {exists($opts->{$_})} qw(Creat Trunc ReadOnly));
  my $nnz    = $opts->{nnz};
  my $ixopts = _ccsio_opts_ix($opts, {%defaults, (defined($nnz) ? (Dims=>[$header->{pdims}->ndims,$nnz]) : qw())});
  my $nzopts = _ccsio_opts_nz($opts, {%defaults, (defined($nnz) ? (Dims=>[$nnz+1]) : qw()), (defined($opts->{Datatype}) ? (Datatype=>$opts->{Datatype}) : qw())});

  ##-- map pdls
  defined(my $ix = PDL->mapfraw($ixFile, $ixopts))
      or confess("ccs_mapfraw(): failed to map ix-file $ixFile: $!");
  defined(my $nz = PDL->mapfraw($nzFile, $nzopts))
      or confess("ccs_mapfraw(): failed to map values-file $nzFile: $!");

  ##-- construct and return
  return PDL::CCS::Nd->newFromWhich($ix,$nz,
				    pdims=>$header->{pdims},
				    vdims=>$header->{vdims},
				    flags=>$header->{flags},
				    sorted=>($opts->{sorted}//1),
				    steal=>1);
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

Copyright (C) 2015-2022, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

L<perl>,
L<PDL>,
L<PDL::CCS::Nd>,
L<PDL::CCS::IO::FITS>,
L<PDL::CCS::IO::MatrixMarket>,
L<PDL::CCS::IO::LDAC>,
...

=cut


1; ##-- make perl happy
