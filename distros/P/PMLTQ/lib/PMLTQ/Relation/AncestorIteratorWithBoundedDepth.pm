package PMLTQ::Relation::AncestorIteratorWithBoundedDepth;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::AncestorIteratorWithBoundedDepth::VERSION = '3.0.2';
# ABSTRACT: Iterates over ancestor nodes to given bound

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use Carp;
use constant CONDITIONS=>0;
use constant MIN=>1;
use constant MAX=>2;
use constant NODE=>3;
use constant DEPTH=>4;
use constant FILE=>5;

sub new  {
  my ($class,$conditions,$min,$max)=@_;
  croak "usage: $class->new(sub{...})" unless ref($conditions) eq 'CODE';
  $min||=0;
  return bless [$conditions,$min,$max],$class;
}
sub clone {
  my ($self)=@_;
  return bless [$self->[CONDITIONS],$self->[MIN],$self->[MAX]], ref($self);
}
sub start  {
  my ($self,$node,$fsfile)=@_;
  my $min = $self->[MIN]||1;
  my $max = $self->[MAX];
  $self->[FILE]=$fsfile;
  my $depth=0;
  while ($node and $depth<$min) {
    $node = $node->parent ;
    $depth++;
  }
  $node=undef if defined($max) and $depth>$max;
  $self->[NODE]=$node;
  $self->[DEPTH]=$depth;
  return ($node && $self->[CONDITIONS]->($node,$fsfile)) ? $node : ($node && $self->next);
}
sub next {
  my ($self)=@_;
  my $conditions=$self->[CONDITIONS];
  my $max = $self->[MAX];
  my $depth = $self->[DEPTH];
  return $self->[NODE]=undef if (defined($max) and $depth>=$max);
  my $n=$self->[NODE]->parent;
  $depth++;
  my $fsfile = $self->[FILE];
  while ($n and !$conditions->($n,$fsfile)) {
    $depth++;
    if (defined($max) and $depth<=$max) {
      $n=$n->parent;
    } else {
      $n=undef;
    }
  }
  $self->[DEPTH]=$depth;
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

1; # End of PMLTQ::Relation::AncestorIteratorWithBoundedDepth

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::AncestorIteratorWithBoundedDepth - Iterates over ancestor nodes to given bound

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
