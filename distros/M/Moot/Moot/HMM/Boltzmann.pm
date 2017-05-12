package Moot::HMM::Boltzmann;
use Carp;
use strict;

our @ISA = qw(Moot::HMM::DynLex);

##======================================================================
## wrappers: config


1; ##-- be happy


__END__

=pod

=head1 NAME

Moot::HMM::Boltzmann - libmoot : HMM : dynamic : lexical probabilites via Boltzmann distribution

=head1 SYNOPSIS

  use Moot;

  $hmm = Moot::HMM::Boltzmann->new();

  ## all methods of Moot::HMM::Dyn supported;
  ## C++ descendants can override e.g. tag_sentence()

  ##-- new accessors:
  ## + lexical probabilities are estimated via
  ##     f(w,t) = dynlex_base^(-dynlex_beta * a.prob)
  $base = $hmm->dynlex_base();
  $beta = $hmm->dynlex_beta();

  ##-- inherited from Moot::HMM::DynLex
  $bool = $hmm->invert_lexp(); ##-- est lex probs p(w|t) as f(w,t)/f(w)=p(t|w) : incorrect but true by default
  $tag  = $hmm->newtag_str();  ##-- tag string to copy for "missing" tags (default="@NEW")
  $tagid = $hmm->newtag_id();  ##-- ID for "missing" tags
  $f = $hmm->newtag_f();       ##-- Raw frequency for 'new' tag, if not already in model.  Default=0.5
  $f = $hmm->Ftw_eps();        ##-- Raw pseudo-frequency smoothing constant (non-log) for f(w,t)


=head1 DESCRIPTION

The Moot module provides an object-oriented interface to the libmoot library
for Hidden Markov Model part-of-speech tagging.

=head1 SEE ALSO

Moot::Constants(3perl),
moot(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
