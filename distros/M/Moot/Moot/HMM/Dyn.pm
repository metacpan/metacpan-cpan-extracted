package Moot::HMM::Dyn;
use Carp;
use strict;

our @ISA = qw(Moot::HMM);

##======================================================================
## wrappers: config

## $hmm = $CLASS->new()
## $hmm = $CLASS->new($opts)
sub new {
  my ($that,$opts) = @_;
  my $hmm = $that->_new();
  $hmm->Moot::HMM::config($opts) if ($opts);
  return $hmm;
}


1; ##-- be happy


__END__

=pod

=head1 NAME

Moot::HMM::Dyn - libmoot : HMM : dynamic

=head1 SYNOPSIS

  use Moot;

  ## all methods inherited from Moot::HMM;
  ## C++ descendants can override e.g. tag_sentence()

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
