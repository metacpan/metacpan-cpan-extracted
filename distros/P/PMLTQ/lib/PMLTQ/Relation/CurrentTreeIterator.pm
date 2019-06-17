package PMLTQ::Relation::CurrentTreeIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::CurrentTreeIterator::VERSION = '3.0.2';
# ABSTRACT: Iterates over nodes of current tree

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use constant CONDITIONS=>0;
use constant NODE=>1;

sub start  {
  my ($self)=@_;
  $TredMacro::this=$TredMacro::root;
  $self->[NODE]=$TredMacro::this;
  return ($TredMacro::this && $self->[CONDITIONS]->($TredMacro::this,TredMacro::CurrentFile())) ? $TredMacro::this : ($TredMacro::this && $self->next);
}
sub next {
  my ($self)=@_;
  my $conditions=$self->[CONDITIONS];
  my $n=$self->[NODE];
  my $fsfile=TredMacro::CurrentFile();
  while ($n) {
    $n = $n->following;
    last if $conditions->($n,$fsfile);
  }
  return $self->[NODE]=$n;
}
sub file {
  return TredMacro::CurrentFile();
}
sub node {
  return $_[0]->[NODE];
}
sub reset {
  my ($self)=@_;
  $self->[NODE]=undef;
}

1; # End of PMLTQ::Relation::CurrentTreeIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::CurrentTreeIterator - Iterates over nodes of current tree

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
