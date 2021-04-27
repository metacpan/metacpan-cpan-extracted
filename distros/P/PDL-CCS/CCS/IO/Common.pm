## File: PDL::CCS::IO::Common.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: common routines for PDL::CCS::Nd I/O

package PDL::CCS::IO::Common;
use PDL::CCS::Config qw(ccs_indx);
use PDL::CCS::Nd;
use PDL;
use Carp qw(confess);
use strict;

our $VERSION = '1.23.15';
our @ISA = ('PDL::Exporter');
our @EXPORT_OK =
  (
   qw(_ccsio_open _ccsio_close),
   qw(_ccsio_read_header _ccsio_parse_header),
   qw(_ccsio_write_header _ccsio_header_lines),
   qw(_ccsio_opts_ix _ccsio_opts_nz),
  );
our %EXPORT_TAGS =
  (
   Func => [],               ##-- respect PDL conventions (hopefully)
   intern => [@EXPORT_OK],
  );


##======================================================================
## pod: headers
=pod

=head1 NAME

PDL::CCS::IO::Common - Common pseudo-private routines for PDL::CCS::Nd I/O

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Nd;
 use PDL::CCS::IO::Common qw(:intern);

 #... stuff happens

=cut

##======================================================================
## private utilities

## \%ixOpts = _ccsio_opts_ix(\%opts)
## \%ixOpts = _ccsio_opts_ix(\%opts,\%defaults)
##  + extracts 'ixX' options from \%opts as 'X' options in \%ixOpts
sub _ccsio_opts_ix {
  my $opts = { map {s/^ix//; ($_=>$_[0]{$_})} grep {/^ix/} keys %{$_[0]//{}} };
  $opts->{$_} //= $_[1]{$_} foreach (keys %{$_[1]//{}});
  return $opts;
}

## \%nzOpts = _ccsio_opts_nz(\%opts)
## \%nzOpts = _ccsio_opts_nz(\%opts,\%defaults)
##  + extracts 'nzX' options from \%opts as 'X' options in \%nzOpts
sub _ccsio_opts_nz {
  my $opts = { map {s/^nz//; ($_=>$_[0]{$_})} grep {/^nz/} keys %{$_[0]//{}} };
  $opts->{$_} //= $_[1]{$_} foreach (keys %{$_[1]//{}});
  return $opts;
}

## $fh_or_undef = _ccsio_open($filename_or_handle,$mode)
sub _ccsio_open {
  my ($file,$mode) = @_;
  return $file if (ref($file));
  $mode = '<' if (!defined($mode));
  open(my $fh, $mode, $file);
  return $fh;
}

## $fh_or_undef = _ccsio_close($filename_or_handle,$fh)
sub _ccsio_close {
  my ($file,$fh) = @_;
  return 1 if (ref($file)); ##-- don't close if we got a handle
  return close($fh);
}


## \%header = _ccsio_read_header( $hfile)
sub _ccsio_read_header {
  my $hFile = shift;
  my $hfh = _ccsio_open($hFile,'<')
    or confess("_ccsio_read_header(): open failed for header-file $hFile: $!");
  binmode($hfh,':raw');
  my @hlines = <$hfh>;
  _ccsio_close($hFile,$hfh)
    or confess("_ccsio_read_header(): close failed for header-file $hFile: $!");
  return _ccsio_parse_header(\@hlines);
}

## \%header = _ccsio_parse_header(\@hlines)
sub _ccsio_parse_header {
  my $hlines = shift;
  my ($magic,$pdims,$vdims,$flags,$iotype) = map {chomp;$_} @$hlines;
  return {
	  magic=>$magic,
	  (defined($pdims) && $pdims ne '' ? (pdims=>pdl(ccs_indx(),[split(' ',$pdims)])) : qw()),
	  (defined($vdims) && $vdims ne '' ? (vdims=>pdl(ccs_indx(),[split(' ',$vdims)])) : qw()),
	  (defined($flags) && $flags ne '' ? (flags=>$flags) : qw()),
	  (defined($iotype) && $iotype ne ''  ? (iotype=>$iotype) : qw()), ##-- added in v1.22.6
	 };
}

## $bool = _ccsio_write_header(\%header, $hfile)
## $bool = _ccsio_write_header(    $ccs, $hfile)
sub _ccsio_write_header {
  my ($header,$hFile) = @_;
  my $hfh = _ccsio_open($hFile,'>')
    or confess("_ccsio_write_header(): open failed for header-file $hFile: $!");
  binmode($hfh,':raw');
  local $, = '';
  print $hfh @{_ccsio_header_lines($header)};
  _ccsio_close($hFile,$hfh)
    or confess("_ccsio_write_header(): close failed for header-file $hFile: $!");
  return 1;
}

## \@header_lines = _ccsio_header_lines(\%header)
## \@header_lines = _ccsio_header_lines( $ccs)
sub _ccsio_header_lines {
  my $header = shift;
  $header = _ccsio_header($header) if (UNIVERSAL::isa($header,'PDL::CCS::Nd'));
  return [
	  map {"$_\n"}
	  (defined($header->{magic}) ? $header->{magic} : ''),
	  (defined($header->{pdims}) ? (join(' ', $header->{pdims}->list)) : ''),
	  (defined($header->{vdims}) ? (join(' ', $header->{vdims}->list)) : ''),
	  (defined($header->{flags}) ? $header->{flags} : $PDL::CCS::Nd::CCSND_FLAGS_DEFAULT),
	  (defined($header->{iotype}) ? $header->{iotype} : $PDL::IO::Misc::deftype),
	 ];
}

## \%header = _ccsio_header( $ccs)
## \%header = _ccsio_header(\%header)
sub _ccsio_header {
  my $ccs = shift;
  return $ccs if (!UNIVERSAL::isa($ccs,'PDL::CCS::Nd'));
  return {
	  magic=>(ref($ccs)." $VERSION"),
	  pdims=>$ccs->pdims,
	  vdims=>$ccs->vdims,
	  flags=>$ccs->flags,
	  iotype=>$ccs->type,
	 };
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
L<PDL::CCS::IO::MatrixMarket>,
L<PDL::CCS::IO::LDAC>,
...

=cut
