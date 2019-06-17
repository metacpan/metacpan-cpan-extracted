package PMLTQ::Relation::DepthFirstPrecedesIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::DepthFirstPrecedesIterator::VERSION = '3.0.2';
# ABSTRACT: Iterates tree using depth first search calling $node->following

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use constant CONDITIONS=>0;
use constant NODE=>1;
use constant FILE=>2;

sub start  {
  my ($self,$parent,$fsfile)=@_;
  if ($fsfile) {
    $self->[FILE]=$fsfile;
  } else {
    $fsfile=$self->[FILE];
  }
  my $n= $parent->following;
  $self->[NODE]=$n;
  return ($n && $self->[CONDITIONS]->($n,$fsfile)) ? $n : ($n && $self->next);
}
sub next {
  my ($self)=@_;
  my $conditions=$self->[CONDITIONS];
  my $n=$self->[NODE]->following();
  my $fsfile=$self->[FILE];
  $n=$n->following() while ($n and !$conditions->($n,$fsfile));
  return $self->[NODE]=$n;
}
sub node {
  return $_[0]->[NODE];
}
sub file {
  return $_[0]->[FILE];
}
sub reset {
  my ($self)=@_;
  $self->[NODE]=undef;
  $self->[FILE]=undef;
}

1; # End of PMLTQ::Relation::DepthFirstPrecedesIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::DepthFirstPrecedesIterator - Iterates tree using depth first search calling $node->following

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
