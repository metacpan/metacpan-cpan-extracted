
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GA;

@EXPORT_OK  = qw(   roulette  roulette_nr  weightselect  weightselect_nr  cumuweightselect  cumuweightselect_nr  ga_make_unique PDL::PP ga_make_unique  tobits  _tobits PDL::PP _tobits  frombits PDL::PP frombits  mutate_bool PDL::PP mutate_bool PDL::PP mutate_range PDL::PP mutate_addrange  mutate_bits PDL::PP _mutate_bits PDL::PP _xover1 PDL::PP _xover2  xover1  xover2 );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::GA::VERSION = 0.07;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GA $VERSION;




use strict;

=pod

=head1 NAME

PDL::GA - Genetic algorithm utilities for PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::GA;

 ##-------------------------------------------------------------
 ## TODO...

=cut







=head1 FUNCTIONS



=cut




*ga_indx = &PDL::indx;



=pod

=head1 Weighted Selection

=cut



=pod

=head2 roulette

=for sig

  Signature: (weightmap(M); %options)
  Options:
    n  => $n
    to => [o]selindices($n)

Stochastic (roulette-wheel) selection of $n objects from
$M objects, governed by the likelihood distribution $weightmap(), allowing repetitions.
Calls PDL::Primitive::vsearch().

=cut

sub roulette {
  my ($wmap,%opts) = @_;
  my ($seli);
  if (defined($opts{to})) {
    $seli = $opts{to};
  } elsif (defined($opts{n})) {
    $seli = zeroes(ga_indx(), (($wmap->dims)[1..($wmap->ndims-1)]), $opts{n}) if (!defined($seli));
    $seli->resize((($wmap->dims)[1..($wmap->ndims-1)]), $opts{n})
      if ($seli->ndims != $wmap->ndims || $seli->dim(-1) != $opts{n});
  } else {
    $seli = zeroes(ga_indx(),1);
  }
  my $wsum = $wmap->sumover->slice(',*1');
  my $selw = PDL->random($seli->dims);
  $selw *= $wsum;
  $selw->vsearch($wmap->cumusumover, $seli);
  return $seli;
}



=pod

=head2 roulette_nr

=for sig

  Signature: (weightmap(M); %options)
  Options:
    n  => $n
    to => [o]selindices($n)

Stochastic (roulette-wheel) selection of $n objects from
$M objects, governed by the likelihood distribution $weightmap(), without repetitions.
Wrapper for cumuweighselect_nr.

=cut

sub roulette_nr {
  my ($wmap,%opts) = @_;
  my ($seli);
  if (defined($opts{to})) {
    $seli = $opts{to};
  } elsif (defined($opts{n})) {
    $seli = zeroes(ga_indx(), (($wmap->dims)[1..($wmap->ndims-1)]), $opts{n}) if (!defined($seli));
    $seli->resize((($wmap->dims)[1..($wmap->ndims-1)]), $opts{n})
      if ($seli->ndims != $wmap->ndims || $seli->dim(-1) != $opts{n});
  } else {
    $seli = zeroes(ga_indx(),1);
  }
  my $wsum = $wmap->sumover->slice(',*1');
  my $selw = PDL->random($seli->dims);
  $selw *= $wsum;
  return cumuweightselect_nr($wmap->cumusumover, $selw, $seli);
}




=pod

=head2 weightselect

=for sig

  Signature: (weightmap(M); selweights(S); [o]selindices(S))

Stochastically select $S objects from a pool $M objects, allowing repetitions.
Likelihood selecting an object $i is given by $weightmap($i).  Target
selection likelihoods are passed as $selweights(), which should have
values in the range [0,sum($weightmap)\(.  Selected targets are
returned as indices in the range [0,$M\( in the PDL $selindices().

See also:
roulette(),
cumuweightselect(),
roulette_nr(),
weightselect_nr(),
cumuweightselect_nr(),
PDL::Primitive::vsearch(),
PDL::Ufunc::cumusumover().

=cut

sub weightselect {
  #my ($wmap,$selw,$seli) = @_;
  return
    #$selw->vsearch($wmap->cumusumover, @_);
    $_[1]->vsearch($_[0]->cumusumover, @_[2..$#_]);
}




=pod

=head2 weightselect_nr

=for sig

  Signature: (weightmap(M); selweights(S); [o]selindices(S))

Like weightselect() without repetition.
Wraps cumuweightselect_nr().

=cut

sub weightselect_nr {
  #my ($wmap,$selw,$seli) = @_;
  return
    #cumuweightselect_nr($wmap->cumusumover,$selw,$seli);
    cumuweightselect_nr($_[0]->cumusumover, @_[1..$#_]);
}




=pod

=head2 cumuweightselect

=for sig

  Signature: (cumuweightmap(M); selweights(S); indx [o]selindices(S))

Stochastically select $S objects from a pool $M objects, allowing repetitions.
Cumulative likelihood selecting an object $i is given by $cumweightmap($i).  Target
selection likelihoods are passed as $selweights(), which should have
values in the range [0,$cumuweightmap[-1]\(.  Selected targets are
returned as indices in the range [0,$M\( in the PDL $selindices().
Really just a wrapper for PDL::Primitive::vsearch().

See also:
roulette(),
weightselect(),
roulette_nr(),
weightselect_nr(),
cumuweightselect_nr(),
PDL::Primitive::vsearch(),
PDL::Ufunc::cumusumover().

=cut

sub cumuweightselect {
  #my ($cwmap,$selw,$seli) = splice(@_,0,2);
  return
    #$selw->vsearch($cwmap, @_);
    $_[1]->vsearch($_[0], @_[2..$#_]);
}




=pod

=head2 cumuweightselect_nr

=for sig

  Signature: (cumuweightmap(M); selweights(S); indx [o]selindices(S); indx [t]trynext(M); byte [t]ignore(M))

Stochastically select $S objects from a pool $M objects, without repetitions.
Really just a wrapper for PDL::Primitive::vesarch() and ga_make_unique().

=cut

sub cumuweightselect_nr {
  my ($cwmap,$selw,$seli,$try,$ignore) = @_;
  $seli = zeroes(ga_indx(),$selw->dims) if (!defined($seli));
  $selw->vsearch($cwmap, $seli);
  $try  = 1+PDL->sequence(ga_indx(),$cwmap->dim(0)) if (!defined($try));
  $seli->inplace->ga_make_unique($try, (defined($ignore) ? $ignore : qw()));
  return $seli;
}





=head2 ga_make_unique

=for sig

  Signature: (indx selected(S); int trynext(M); indx [o]unique_selected(S); byte [t]ignore(M))


Remove repetitions from a vector of selected items $selected() while retaining vector length.
$selected() should have values in the range [0..($M-1)], and it must be the case
that $S <= $M.
The vector $trynext() is used to (iteratively) map a non-unique item to the "next-best" item,
and are implicitly interpreted modulo $M.
The temporary $ignore is used to record which items have already appeared.
May be run in-place on $selected().
Generally, $trynext() should be something like 1+sequence($M).


=for bad

ga_make_unique processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ga_make_unique = \&PDL::ga_make_unique;




=pod

=head1 Gene Encoding and Decoding

=cut




=pod

=head2 tobits

=for sig

  Signature: (ints(); [o]bits(B))

Extract individual bits from integer type pdls.
Output pdl will be created with appropriate dimensions if unspecified.
Serious waste of memory, since PDL does not have a 'bit' type.

=cut

sub tobits {
  my ($ints,$bits) = @_;
  $bits = zeroes($ints->type,8*PDL::howbig($ints->type),$ints->dims) if (!defined($bits));
  _tobits($ints,$bits);
  return $bits;
}





=head2 _tobits

=for sig

  Signature: (a(); [o]bits(B))

(Low-level method)

Extract individual bits from integer type pdls.
Output pdl $bits() must be specified!


=for bad

_tobits does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_tobits = \&PDL::_tobits;





=head2 frombits

=for sig

  Signature: (bits(B); [o]a())

=for ref

Compress expanded bit-pdls to integer types.


=for bad

frombits does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*frombits = \&PDL::frombits;




=pod

=head1 Mutation

=cut





=head2 mutate_bool

=for sig

  Signature: (genes(G); float+ rate(G); [o]mutated(G))

=for ref

Mutate binary-valued (boolean) genes.

=for bad

mutate_bool does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mutate_bool = \&PDL::mutate_bool;





=head2 mutate_range

=for sig

  Signature: (genes(G); float+ rate(G); min(G); max(G); [o]mutated(G))

=for ref

Mutate genes in the range [$min,$max\(.

=for bad

mutate_range does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mutate_range = \&PDL::mutate_range;





=head2 mutate_addrange

=for sig

  Signature: (genes(G); float+ rate(G); min(G); max(G); [o]mutated(G))

=for ref

Mutate genes by adding values in the range [$min,$max\(.

=for bad

mutate_addrange does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*mutate_addrange = \&PDL::mutate_addrange;




=pod

=head2 mutate_bits

=for sig

  Signature: (genes(G); rate(); [o]mutated(G))

Mutate traditional bit-string genes.
Calls mutate_bool(), tobits(), frombits().

=cut

sub mutate_bits {
  #my ($pop,$rate,$dst) = @_;
  #return $pop->tobits->inplace->mutate_bool($rate)->frombits(defined($dst) ? $dst : qw());
  return $_[0]->tobits->inplace->mutate_bool($_[1])->frombits(@_[2..$#_]);
}





=head2 _mutate_bits

=for sig

  Signature: (genes(G); float+ rate(G); [o]mutated(G))

(Low-level method)

Mutate traditional bit-string genes.
This should be equivalent to mutate_bits(), but appears to involve
less overhead (faster for many calls).


=for bad

_mutate_bits does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_mutate_bits = \&PDL::_mutate_bits;




=pod

=head1 Crossover

=cut





=head2 _xover1

=for sig

  Signature: (mom(G); dad(G); indx xpoint(); [o]kid(G))

(Low-level method)

Single-point crossover.
$kid() is computed by single-point crossover of $mom() (initial subsequence)
and $dad() (final subsequence).  For symmetric crossover (two offspring per crossing),
call this method twice:

  $kid1 = _xover1($mom, $dad, $points);
  $kid2 = _xover1($dad, $mom, $points);



=for bad

_xover1 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_xover1 = \&PDL::_xover1;





=head2 _xover2

=for sig

  Signature: (mom(G); dad(G); indx xstart(); int xend(); [o]kid(G))

(Low-level method)

Dual-point crossover.
$kid() is computed by dual-point crossover of $mom() (initial and final subsequences)
and $dad() (internal subsequence).  For symmetric crossover (two offspring per crossing),
call this method twice:

  $kid1 = _xover2($mom, $dad, $points1, $points2);
  $kid2 = _xover2($dad, $mom, $points1, $points2);



=for bad

_xover2 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_xover2 = \&PDL::_xover2;




=pod

=head2 xover1

=for sig

  Signature: (mom(G); dad(G); float+ rate(); [o]kid(G))

Random single-point crossover.
Calls _xover1().

=cut

sub xover1 {
  my ($mom, $dad, $rate, $kid) = @_;
  my $xwhich = (PDL->random($mom->dim(1)) < $rate)->which;
  if ($xwhich->isempty) {
    return ($mom->is_inplace
	    ? $mom
	    : (defined($kid)
	       ? ($kid .= $mom)
	       : ($kid  = pdl($mom))));
  }
  my $xpoint = PDL->zeroes(ga_indx(),$mom->dim(1)) + $mom->dim(0);
  $xpoint->index($xwhich) .= PDL->random($xwhich->nelem)*($mom->dim(0)-1)+1;
  return _xover1($mom,$dad, $xpoint, (defined($kid) ? $kid : qw()));
}




=pod

=head2 xover2

=for sig

  Signature: (mom(G); dad(G); float+ rate(); [o]kid(G))

Random dial-point crossover.
Calls _xover2().

=cut

sub xover2 {
  my ($mom, $dad, $rate, $kid) = @_;
  my $xwhich = (PDL->random($mom->dim(1)) < $rate)->which;
  if ($xwhich->isempty) {
    return ($mom->is_inplace
	    ? $mom
	    : (defined($kid)
	       ? ($kid .= $mom)
	       : ($kid  = pdl($mom))));
  }
  my $xpoint1 = PDL->zeroes(ga_indx(),$mom->dim(1)) + $mom->dim(0);
  $xpoint1->index($xwhich) .= PDL->random($xwhich->nelem)*($mom->dim(0)-1)+1;
  my $xpoint2 = pdl($xpoint1);
  $xpoint2->index($xwhich) += 1+PDL->random($xwhich->nelem)*($mom->dim(0)-$xpoint1->index($xwhich));
  return _xover2($mom,$dad, $xpoint1, $xpoint2, (defined($kid) ? $kid : qw()));
}




##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

Probably many.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.org<gt>

=head2 Copyright Policy

Copyright (C) 2006-2007, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl).

=cut



;



# Exit with OK status

1;

		   