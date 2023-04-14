
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::HMM;

@EXPORT_OK  = qw( PDL::PP logzero PDL::PP logadd PDL::PP logdiff PDL::PP logsumover PDL::PP hmmfw  hmmalpha PDL::PP hmmfwq  hmmalphaq PDL::PP hmmbw  hmmbeta PDL::PP hmmbwq  hmmbetaq  hmmexpect0 PDL::PP hmmexpect PDL::PP hmmexpectq  hmmmaximize PDL::PP hmmviterbi PDL::PP hmmviterbiq PDL::PP hmmpath PDL::PP hmmpathq );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::HMM::VERSION = 0.06007;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::HMM $VERSION;




=pod

=head1 NAME

PDL::HMM - Hidden Markov Model utilities in PDL

=head1 SYNOPSIS

 use PDL::HMM;

 ##-----------------------------------------------------
 ## Dimensions

 $N = $number_of_states;
 $M = $number_of_symbols;
 $T = $length_of_input;

 $A = $maximum_ambiguity;

 ##-----------------------------------------------------
 ## Parameters

 $af     = log(random($N,$N));
 $bf     = log(random($N,$M));
 $pif    = log(random($N));
 $omegaf = log(random($N));

 @theta = ($a,$b,$pi,$omega) = hmmmaximize($af,$bf,$pif,$omegaf);

 $o  = long(rint($M*random($T)));

 maximum_n_ind(dice_axis($a->logsumover+$pi+$b, 1,$o),
               ($oq=zeroes(long,$A,$T))); ##-- for constrained variants

 ##-----------------------------------------------------
 ## Log arithmetic

 $log0 = logzero;
 $logz = logadd(log($x),log($y));
 $logz = logdiff(log($x),log($y));
 $logz = logsumover(log($x));

 ##-----------------------------------------------------
 ## Sequence Probability

 $alpha  = hmmfw ($a,$b,$pi,    $o     ); ##-- forward (full)
 $alphaq = hmmfwq($a,$b,$pi,    $o, $oq); ##-- forward (constrained)

 $beta   = hmmbw ($a,$b,$omega,  $o    ); ##-- backward (full)
 $betaq  = hmmbwq($a,$b,$omega,  $o,$oq); ##-- backward (constrained)

 ##-----------------------------------------------------
 ## Parameter Estimation

 @expect = ($ea,$eb,$epi,$eomega) = hmmexpect0(@theta);    ##-- initialize

 hmmexpect (@theta, $o,     $alpha, $beta,  $ea,$eb,$epi); ##-- expect (full)
 hmmexpectq(@theta, $o,$oq, $alphaq,$betaq, $ea,$eb,$epi); ##-- expect (constrained)

 ($a,$b,$pi,$omega) = hmmmaximize($ea,$eb,$epi,$eomega);   ##-- maximize

 ##-----------------------------------------------------
 ## Sequence Analysis

 ($delta,$psi)   = hmmviterbi ($a,$b,$pi, $o);     ##-- trellis (full)
 ($deltaq,$psiq) = hmmviterbiq($a,$b,$pi, $o,$oq); ##-- trellis (constrained)

 $paths  = hmmpath (     $psi,  sequence($N));     ##-- backtrace (full)
 $pathsq = hmmpathq($oq, $psiq, sequence($A));     ##-- backtrace (constrained)

=cut







=head1 FUNCTIONS



=cut




=pod

=head1 Log Arithmetic

=cut




=head2 logzero

=for sig

  Signature: (float+ [o]a())

=for ref

Approximates $a() = log(0), avoids nan.

=for bad

logzero() handles bad values.  The state of the output PDL is always good.

=cut






*logzero = \&PDL::logzero;





=head2 logadd

=for sig

  Signature: (a(); b(); [o]c())

=for ref

Computes $c() = log(exp($a()) + exp($b())), should be more stable.

=for bad

logadd does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*logadd = \&PDL::logadd;





=head2 logdiff

=for sig

  Signature: (a(); b(); [o]c())

=for ref

Computes log symmetric difference c = log(exp(max(a,b)) - exp(min(a,b))), may be more stable.

=for bad

logdiff does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*logdiff = \&PDL::logdiff;





=head2 logsumover

=for sig

  Signature: (a(n); [o]b())

=for ref

Computes $b() = log(sumover(exp($a()))), should be more stable.

=for bad

logsumover does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*logsumover = \&PDL::logsumover;



=pod

=head1 Sequence Probability

=cut




=head2 hmmfw

=for sig

  Signature: (a(N,N); b(N,M); pi(N);  o(T);  [o]alpha(N,T))

Compute forward probability (alpha) matrix
for input $o given model parameters
@theta = ($a, $b, $pi, $omega).

Output (pseudocode) for all 0<=i<N, 0<=t<T:

 $alpha(i,t) = log P( $o(0:t), q(t)==i | @theta )

Note that the final-state probability vector $omega() is neither
passed to this function nor used in the computation, but
can be used to compute the final sequence probability for $o as:

  log P( $o | @theta ) = logsumover( $omega() + $alpha(:,t-1) )



=for bad

hmmfw does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmfw = \&PDL::hmmfw;



*hmmalpha = \&hmmfw;



=head2 hmmfwq

=for sig

  Signature: (a(N,N); b(N,M); pi(N);  o(T); oq(Q,T);  [o]alphaq(Q,T))

Compute constrained forward probability (alphaq) matrix
for input $o given model parameters
@theta = ($a, $b, $pi, $omega),
considering only the initial
non-negative state indices in $oq(:,t) for each observation $o(t).

Output (pseudocode) for all 0<=qi<Q, 0<=t<T:

 $alphaq(qi,t) = log P( $o(0:t), q(t)==$oq(qi,t) | @theta )

Note that the final-state probability vector $omega() is neither
passed to this function nor used in the computation, but
can be used to compute the final sequence probability for $o as:

  log P( $o | @theta ) = logsumover( $alphaq(:,t-1) + $omega($oqTi) )

where:

  $oqTi = $oq(:,t-1)->where($oq(:,t-1)>=0)



=for bad

hmmfwq does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmfwq = \&PDL::hmmfwq;



*hmmalphaq = \&hmmfwq;



=head2 hmmbw

=for sig

  Signature: (a(N,N); b(N,M); omega(N); o(T); [o]beta(N,T))

Compute backward probability (beta) matrix
for input $o given model parameters
@theta = ($a, $b, $pi, $omega).

Output (pseudocode) for all 0<=i<N, 0<=t<T:

 $beta(i,t) = log P( $o(t+1:T-1) | q(t)==i, @theta )

Note that the initial-state probability vector $pi() is neither
passed to this function nor used in the computation, but
can be used to compute the final sequence probability for $o as:

  log P( $o | @theta ) = logsumover( $pi() + $b(:,$o(0)) + $beta(:,0) )



=for bad

hmmbw does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmbw = \&PDL::hmmbw;



*hmmbeta = \&hmmbw;



=head2 hmmbwq

=for sig

  Signature: (a(N,N); b(N,M); omega(N); o(T); oq(Q,T); [o]betaq(Q,T))

Compute constrained backward probability (betaq) matrix
for input $o given model parameters
@theta = ($a, $b, $pi, $omega),
considering only the initial non-negative state indices in $oq(:,t) for
each observation $o(t).

Output (pseudocode) for all 0<=qi<Q, 0<=t<T:

 $betaq(qi,t) = log P( $o(t+1:T-1) | q(t)==$oq(qi,t), @theta )

Note that the initial-state probability vector $pi() is neither
passed to this function nor used in the computation, but
can be used to compute the final sequence probability for $o as:

  log P( $o | @theta ) = logsumover( $betaq(:,0) + $pi($oq0i) + $b($oq0i,$o(0)) )

where:

  $oq0i = $oq(:,0)->where( $oq(:,0) >= 0 );



=for bad

hmmbwq does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmbwq = \&PDL::hmmbwq;



*hmmbetaq = \&hmmbwq;

=pod

=head1 Parameter Estimation

=head2 hmmexpect0

=for sig

  Signature: (a(N,N); b(N,M); pi(N); omega(N); [o]ea(N,N); [o]eb(N,M); [o]epi(N); [o]eomega(N))

Initializes expectation matrices $ea(), $eb() and $epi() to logzero().
For use with hmmexpect().

=cut

sub hmmexpect0 {
  my ($a,$b,$pi,$omega, $ea,$eb,$epi,$eomega) = @_;

  $ea  = zeroes($a->type,  $a->dims)  if (!defined($ea));
  $eb  = zeroes($b->type,  $b->dims)  if (!defined($eb));
  $epi = zeroes($pi->type, $pi->dims) if (!defined($epi));
  $eomega = zeroes($omega->type, $omega->dims) if (!defined($eomega));

  $ea  .= PDL::logzero();
  $eb  .= PDL::logzero();
  $epi .= PDL::logzero();
  $eomega .= PDL::logzero();

  return ($ea,$eb,$epi,$eomega);
}






=head2 hmmexpect

=for sig

  Signature: (a(N,N); b(N,M); pi(N); omega(N); o(T); alpha(N,T); beta(N,T); [o]ea(N,N); [o]eb(N,M); [o]epi(N); [o]eomega(N))

Compute partial Baum-Welch re-estimation of the model @theta = ($a, $b, $pi, $omega)
for the observation sequence $o() with forward- and backward-probability
matrices $alpha(), $beta().  Result is recorded as log pseudo-frequencies
in the expectation matrices $ea(), $eb(), $epi(), and $eomega(), which are required parameters,
and should have been initialized (e.g. by L</hmmexpect0>()) before calling this function.

Can safely be called sequentially for incremental reestimation.


=for bad

hmmexpect does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmexpect = \&PDL::hmmexpect;





=head2 hmmexpectq

=for sig

  Signature: (a(N,N); b(N,M); pi(N); omega(N); o(T); oq(Q,T); alphaq(Q,T); betaq(Q,T); [o]ea(N,N); [o]eb(N,M); [o]epi(N); [o]eomega(N))

Compute constrained partial Baum-Welch re-estimation of the model @theta = ($a, $b, $pi, $omega)
for the observation sequence $o(), 
with constrained forward- and backward-probability
matrices $alphaq(), $betaq(),
considering only the initial non-negative state
indices in $oq(:,t) for observation $o(t).
Result is recorded as log pseudo-frequencies
in the expectation matrices $ea(), $eb(), $epi(), and $eomega(), which are required parameters,
and should have been initialized (e.g. by L</hmmexpect0>()) before calling this function.

Can safely be called sequentially for incremental reestimation.


=for bad

hmmexpectq does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmexpectq = \&PDL::hmmexpectq;



=pod

=head2 hmmmaximize

=for sig

  Signature: (Ea(N,N); Eb(N,M); Epi(N); Eomega(N); [o]ahat(N,N); [o]bhat(N,M); [o]pihat(N); [o]omegahat(N));

Maximizes expectation values from $Ea(), $Eb(), $Epi(), and $Eomega()
to log-probability matrices $ahat(), $bhat(), $pihat(), and $omegahat().
Can also be used to compile a maximum-likelihood model
from log-frequency matrices.

=cut

sub hmmmaximize {
  my ($ea,$eb,$epi,$eomega, $ahat,$bhat,$pihat,$omegahat) = @_;

  $ahat  = zeroes($ea->type,  $ea->dims)  if (!defined($ahat));
  $bhat  = zeroes($eb->type,  $eb->dims)  if (!defined($bhat));
  $pihat = zeroes($epi->type, $epi->dims) if (!defined($pihat));
  $omegahat = zeroes($eomega->type, $eomega->dims) if (!defined($omegahat));

  my $easumover = $ea->xchg(0,1)->logsumover->inplace->logadd($eomega);

  $ahat  .= $ea  - $easumover;
  $bhat  .= $eb  - $eb->xchg(0,1)->logsumover;
  $pihat .= $epi - $epi->logsumover;
  $omegahat .= $eomega - $easumover;

  return ($ahat,$bhat,$pihat,$omegahat);
}



=pod

=head1 Sequence Analysis

=cut




=head2 hmmviterbi

=for sig

  Signature: (a(N,N); b(N,M); pi(N); o(T); [o]delta(N,T); int [o]psi(N,T))

Computes Viterbi algorithm trellises $delta() and $psi() for the
observation sequence $o() given the model parameters @theta = ($a,$b,$pi,$omega).

Outputs:

Probability matrix $delta(): log probability of best path to state $j at time $t:

 $delta(j,t) = max_{q(0:t)} log P( $o(0:t), q(0:t-1), $q(t)==j | @theta )

Path backtrace matrix $psi(): best predecessor for state $j at time $t:

 $psi(j,t) = arg_{q(t-1)} max_{q(0:t)} P( $o(0:t), q(0:t-1), $q(t)==j | @theta )

Note that if you are using termination probabilities $omega(),
then in order to find the most likely final state, you need to
compute the contribution of $omega() yourself, which is easy
to do:

 $best_final_q = maximum_ind($delta->slice(",-1") + $omega);



=for bad

hmmviterbi does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmviterbi = \&PDL::hmmviterbi;





=head2 hmmviterbiq

=for sig

  Signature: (a(N,N); b(N,M); pi(N); o(T); oq(Q,T); [o]deltaq(Q,T); int [o]psiq(Q,T))

Computes constrained Viterbi algorithm trellises $deltaq() and $psiq() for the
observation sequence $o() given the model parameters @theta = ($a,$b,$pi,$omega),
considering only the initial non-negative state indices $oq(:,t) for each
observarion $o(t).

Outputs:

Constrained probability matrix $deltaq(): log probability of best path to state $oq(j,t) at time $t:

 $deltaq(j,t) = max_{j(0:t)} log P( $o(0:t), q(0:t-1)==$oq(:,j(0:t-1)), q(t)==$oq(j,t) | @theta )

Constrained path backtrace matrix $psiq(): best predecessor index for state $oq(j,t) at time $t:

 $psiq(j,t) = arg_{j(t-1)} max_{j(0:t)} P( $o(0:t), q(0:t-1)=$oq(:,j(0:t-1)), q(t)==$oq(j,t) | @theta )

Note that if you are using termination probabilities $omega(),
then in order to find the most likely final state, you need to
compute the contribution of $omega() yourself, which is quite easy
to do:

 $best_final_j = maximum_ind($deltaq->slice(",-1") + $omega->index($oq->slice(",(-1)")))



=for bad

hmmviterbiq does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmviterbiq = \&PDL::hmmviterbiq;





=head2 hmmpath

=for sig

  Signature: (psi(N,T); int qfinal(); int [o]path(T))

Computes best-path backtrace $path() for the final state $qfinal()
from completed Viterbi trellis $psi().

Outputs:

Path backtrace $path(): state (in best sequence) at time $t:

 $path(t) = arg_{q(t)} max_{q(0:T-1)} log P( $o(), q(0:T-2), $q(T-1)==$qfinal() | @theta )

This even threads over multiple final states, if specified,
so you can align paths to their final states just by calling:

 $bestpaths = hmmpath($psi, sequence($N));

Note that $path(T-1) == $qfinal(): yes, this is redundant,
but also tends to be quite convenient.



=for bad

hmmpath does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmpath = \&PDL::hmmpath;





=head2 hmmpathq

=for sig

  Signature: (oq(Q,T); psiq(Q,T); int qfinalq(); int [o]path(T))

Computes constrained best-path backtrace $path() for the final state index $qfinalq()
from completed constrained Viterbi trellis $psiq().

Outputs:

Path backtrace $path(): state (in best sequence) at time $t:

 $path(t) = arg_{q(t)} max_{q(0:T-1)} log P( $o(), q(0:T-2), $q(T-1)==$oq($qfinalq(),T-1) | @theta )

This is really just a convenience method for dealing with constrained
lookup -- the same thing can be accomplished using hmmpath() and
some PDL index magic.



=for bad

hmmpathq does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hmmpathq = \&PDL::hmmpathq;





##---------------------------------------------------------------------
=pod

=head1 COMMON PARAMETERS

HMMs are specified by parameters $a(N,N), $b(N,M), $pi(N), and $omega(N);
input sequences are represented as vectors $o(T) of integer values in the range [0..M-1],
where the following notational conventions are used:

=over 4


=item States:

The model has $N states, denoted $q,
0 <= $q < $N.


=item Alphabet:

The input- (aka "observation-") alphabet of the model has $M elements,
denoted $o(t), 0 <= $o(t) < $M.


=item Time indices:

Time indices are denoted $t,
1 <= $t < $T.


=item Input Sequences:

Input- (aka "observation-") sequences are represented as vectors of
of length $T whose component values are in the range [0..M-1],
i.e. alphabet indices.



=item Initial Probabilities:

The vector $pi(N) gives the (log) initial state probability distribution:

 $pi(i) = log P( $q(0)==i )



=item Final Probabilities:

The vector $omega(N) gives the (log) final state probability distribution:

 $omega(i) = log P( $q($T)==i )

This parameter is a nonstandard extension.
You can simulate the behavior of more traditional definitions
(such as that given in Rabiner (1989)) by setting:

 $omega = zeroes($N);

wherever it is required.



=item Arc Probabilities:

The matrix $a(N,N) gives the (log) conditional state-transition probability distribution:

 $a(i,j) = log P( $q(t+1)==j | $q(t)==i )



=item Emission Probabilities:

The matrix $b(N,M) gives the (log) conditional symbol emission probability:

 $b(j,o) = log P( $o(t)==o | $q(t)==j )



=back

=cut

##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

Implementation based largely on the formulae in:
L. E. Rabiner, "A tutorial on Hidden Markov Models and selected
applications in speech recognition," Proceedings of the IEEE 77:2,
Februrary, 1989, pages 257--286.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

Probably many.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

Copyright (C) 2005, 2006, 2008, 2011 by Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl).

=cut



;



# Exit with OK status

1;

		   