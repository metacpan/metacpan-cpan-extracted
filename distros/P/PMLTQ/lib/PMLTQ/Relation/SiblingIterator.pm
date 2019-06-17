package PMLTQ::Relation::SiblingIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::SiblingIterator::VERSION = '3.0.2';
# ABSTRACT: Iterates over siblings given node

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use constant CONDITIONS=>0;
use constant NODE=>1;
use constant FILE=>2;
use constant START=>3;

sub start  {
  my ($self,$start_node,$fsfile)=@_;
  $self->[FILE]=$fsfile;
  $self->[START]=$start_node;
  my $n = $start_node->parent;
  $n=$n && $n->firstson;
  $n=$n->rbrother if $n && $n==$start_node;
  $self->[NODE]=$n;
  return ($n && $self->[CONDITIONS]->($n,$fsfile)) ? $n : ($n && $self->next);
}
sub next {
  my ($self)=@_;
  my $conditions=$self->[CONDITIONS];
  my $n=$self->[NODE]->rbrother;
  my $start_node = $self->[START];
  my $fsfile = $self->[FILE];
  $n=$n->rbrother while ($n and !($n!=$start_node and $conditions->($n,$fsfile)));
  return $_[0]->[NODE]=$n;
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
  $self->[START]=undef;
}

1; # End of PMLTQ::Relation::SiblingIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::SiblingIterator - Iterates over siblings given node

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
