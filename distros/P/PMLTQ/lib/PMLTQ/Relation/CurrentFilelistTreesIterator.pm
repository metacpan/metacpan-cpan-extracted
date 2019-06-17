package PMLTQ::Relation::CurrentFilelistTreesIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::CurrentFilelistTreesIterator::VERSION = '3.0.2';
# ABSTRACT: Iterates over trees in files of given file list (calling TredMacro::NextFile())

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use constant CONDITIONS=>0;
use constant NODE=>1;

our $PROGRESS; ### newly added
our $STOP; ### newly added

sub start  {
  my ($self)=@_;
  TredMacro::GotoFileNo(0);
  $TredMacro::this=$TredMacro::root;
  $self->[NODE]=$TredMacro::this;
  my $fsfile = $TredMacro::grp->{FSFile};
  return ($TredMacro::this && $self->[CONDITIONS]->($TredMacro::this,$fsfile)) ? $TredMacro::this : ($TredMacro::this && $self->next);
}
sub next {
  my ($self)=@_;
  my $conditions=$self->[CONDITIONS];
  my $n=$self->[NODE];
  my $fsfile = $TredMacro::grp->{FSFile};
  while ($n) {
    $n = $n->following
      || (($PROGRESS ? $PROGRESS->() : 1) && $STOP && do { $n = undef; last })
      ||  (TredMacro::NextFile() && ($fsfile=$TredMacro::grp->{FSFile}) && $TredMacro::this);
    last if $conditions->($n,$fsfile);
  }
  return $self->[NODE]=$n;
}
sub node {
  return $_[0]->[NODE];
}
sub file {
  return $TredMacro::grp->{FSFile};
}
sub reset {
  my ($self)=@_;
  $self->[NODE]=undef;
}

1; # End of PMLTQ::Relation::CurrentFilelistTreesIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::CurrentFilelistTreesIterator - Iterates over trees in files of given file list (calling TredMacro::NextFile())

=head1 VERSION

version 3.0.2

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
