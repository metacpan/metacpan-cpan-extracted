##-*- Mode: CPerl -*-
##
## File: PDL::Ngrams.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: N-Gram utilities for PDL
##======================================================================

package PDL::Ngrams;
use strict;

##======================================================================
## Export hacks
use PDL;
use PDL::Exporter;
use PDL::VectorValued;
use PDL::Ngrams::Utils;
our @ISA = qw(PDL::Exporter);
our @EXPORT_OK =
  (
   (@PDL::Ngrams::Utils::EXPORT_OK), ##-- inherited
   qw(ng_cofreq ng_rotate),
   qw(_ng_qsortvec), ##-- compat
  );
our %EXPORT_TAGS =
  (
   Func => [@EXPORT_OK],               ##-- respect PDL conventions (hopefully)
  );

our $VERSION = '0.11'; ##-- use perl-reversion to update

##======================================================================
## pod: header
=pod

=head1 NAME

PDL::Ngrams - N-Gram utilities for PDL

=head1 SYNOPSIS

 use PDL;
 use PDL::Ngrams;

 ##---------------------------------------------------------------------
 ## Basic Data
 $toks = rint(10*random(10));

 ##---------------------------------------------------------------------
 ## ... stuff happens


=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

PDL::Ngrams provides basic utilities for tracking N-grams over PDL vectors.

=cut

##======================================================================
## pod: Functions
=pod

=head1 FUNCTIONS

=cut

##======================================================================
## backwards-compatibility aliases
*PDL::_ng_qsortvec = *_ng_qsortvec = \&PDL::vv_qsortvec;

##======================================================================
## Run-Length Encoding/Decoding: n-dimensionl
=pod

=head1 Counting N-Grams over PDLs

=cut

##----------------------------------------------------------------------
## ng_cofreq()
=pod

=head2 ng_cofreq

=for sig

  Signature: (toks(@adims,N,NToks); %args)

  Returns: (int [o]ngramfreqs(NNgrams); [o]ngramids(@adims,N,NNgrams))

Keyword arguments (optional):

  norotate => $bool,                      ##-- if true, $toks() will NOT be rotated along $N
  boffsets => $boffsets(NBlocks)          ##-- block-offsets in $toks() along $NToks
  delims   => $delims(@adims,N,NDelims)   ##-- delimiters to splice in at block boundaries

Count co-occurrences (esp. N-Grams) over a token vector $toks.
This function really just wraps ng_delimit(), ng_rotate(), vv_qsortvec(), and rlevec().

=cut

*PDL::ng_cofreq = \&ng_cofreq;
sub ng_cofreq {
  my ($toks,%args) = @_;
  ##
  ##-- sanity checks
  barf('Usage: ngrams($toks,%args)') if (!defined($toks));
  my @adims      = $toks->dims;
  my ($N,$NToks) = splice(@adims, $#adims-1, 2);
  ##
  ##-- splice in some delimiters (maybe)
  my ($dtoks);
  if (defined($args{boffsets}) && defined($args{delims})) {
    my $adslice = (@adims ? join(',', (map {"*$_"} @adims),'') : '');
    $dtoks = ng_delimit($toks->mv(-1,0),
			$args{boffsets}->slice(",${adslice}*$N"),
			$args{delims}->mv(-1,0),
		       )->mv(0,-1);
  } else {
    $dtoks = $toks;
  }
  ##
  ##-- rotate components (maybe)
  my $NDToks = $dtoks->dim(-1);
  my ($ngvecs);
  if ($args{norotate}) { $ngvecs=$dtoks; }
  else                 { $ngvecs=ng_rotate($dtoks); }
  ##
  ##-- sort 'em & count 'em
  my @ngvdims = $ngvecs->dims;
  ##
  ## ERRORS on next line (RT bug #108472) for t/04_cofreq.t (PDL-Ngrams v0.05003, PDL v2.0.14, Thu, 05 Nov 2015 10:28:13 +0100)
  ##  + Error message: 'Probably false alloc of over 1Gb PDL! (set $PDL::BIGPDL = 1 to enable) at ../blib/lib/PDL/Ngrams.pm line 136.'
  ##  + original line (v0.05003): $ngvecs = $ngvecs->clump(-2)->vv_qsortvec();
  ##  + CASE 1:
  ##    - input $ngvecs has dims [2,13]
  ##    - $ngvecs->clump(-2) should also have dims [2,13], but winds up with dims [1,0,0,2,13], which is just bizarre
  ##  + CASE 2:
  ##    - $ngvecs has dims [3,2,13]
  ##    - $ngvecs->clump(-2) should have dims [6,13], but gets dims [1,0,0,2,13], which apparently leads to 'false alloc' error in later comparisons
  ##  + workaround: compute non-negative argument for clump() as (1+$ngvecs->ndims-2): this seems to work
  $ngvecs     = $ngvecs->clump(1+$ngvecs->ndims-2)->vv_qsortvec();
  my ($ngfreq,$ngelts) = rlevec($ngvecs);
  my $ngwhich          = which($ngfreq);
  ##
  ##-- reshape results (using @ngvdims)
  $ngelts = $ngelts->reshape(@ngvdims);
  ##
  ##.... and return
  return ($ngfreq->index($ngwhich), $ngelts->dice_axis(-1,$ngwhich));
}

##======================================================================
## N-Gram construction: rotation
=pod

=head2 ng_rotate

  Signature: (toks(@adims,N,NToks); [o]rtoks(@adims,N,NToks-N+1))

Create a co-occurrence matrix by rotating a (delimited) token vector $toks().
Returns a matrix $rtoks() suitable for passing to ng_cofreq().

=cut

*PDL::ng_rotate = \&ng_rotate;
sub ng_rotate {
  my ($toks,$rtoks) = @_;

  barf("Usage: ng_rotate (toks(NAttrs,N,NToks), [o]rtoks(NAttrs,N,NToks-N-1))")
    if (!defined($toks));

  my @adims = $toks->dims();
  $rtoks = zeroes($toks->type, @adims) if (!defined($rtoks));
  my $NToks = pop(@adims);
  my $N     = pop(@adims);
  my ($i);
  foreach $i (0..($N-1)) {
    ##-- the following line pukes on cpan testers 5.15.x with: "Can't modify non-lvalue subroutine call at ..."
    #$rtoks->dice_axis(-2,$i) .= $toks->dice_axis(-2,$i)->xchg(-1,0)->rotate(-$i)->xchg(0,-1);
    ##
    my $rtoks_i = $rtoks->dice_axis(-2,$i);
    $rtoks_i .= $toks->dice_axis(-2,$i)->xchg(-1,0)->rotate(-$i)->xchg(0,-1);
  }
  $rtoks = $rtoks->xchg(-1,0)->slice("0:-$N")->xchg(-1,0);

  return $rtoks;
}


##======================================================================
## Delimit / Splice
=pod

=head1 Delimiter Insertion and Removal

The following functions can be used to add or remove delimiters to a PDL vector.
This can be useful to add or remove beginning- and/or end-of-word markers to rsp.
from a PDL vector, before rsp. after constructing a vector of N-gram vectors.

=cut

##----------------------------------------------------------------------
## ng_delimit()
=pod

=head2 ng_delimit

=for sig

  Signature: (toks(NToks); indx boffsets(NBlocks); delims(NDelims); [o]dtoks(NDToks))

Add block-delimiters (e.g. BOS,EOS) to a vector of raw tokens.

See L<PDL::Ngrams::Utils/"ng_delimit">.

=cut

##----------------------------------------------------------------------
## ng_undelimit()
=pod

=head2 ng_undelimit

  Signature: (dtoks(NDToks); indx boffsets(NBlocks); int NDelims(); [o]toks(NToks))

Remove block-delimiters (e.g. BOS,EOS) from a vector of delimited tokens.

See L<PDL::Ngrams::Utils/"ng_undelimit">.

=cut


1; ##-- make perl happy


##======================================================================
## pod: Functions: low-level
=pod

=head2 Low-Level Functions

Some additional low-level functions are provided in the
PDL::Ngrams::Utils
package.
See L<PDL::Ngrams::Utils> for details.

=cut

##======================================================================
## pod: Footer
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=head1 COPYRIGHT

Copyright (c) 2007-2022, Bryan Jurish.  All rights reserved.

This package is free software.  You may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl), PDL::Ngrams::Utils(3perl)

=cut
