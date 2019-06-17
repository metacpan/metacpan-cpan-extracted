package PMLTQ::Relation::SiblingIteratorWithDistance;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::SiblingIteratorWithDistance::VERSION = '3.0.2';
# ABSTRACT: Iterates over siblings given node with boudaries

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use Carp;
use constant CONDITIONS=>0;
use constant MIN=>1;
use constant MAX=>2;
use constant NODE=>3;
use constant DIST=>4;
use constant FILE=>5;
use constant START=>6;

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
# the iterator will first go right from the start node,
# then left
sub start  {
  my ($self,$node,$fsfile)=@_;
  my $min = $self->[MIN];
  my $max = $self->[MAX];
  $self->[FILE]=$fsfile;
  $self->[START]=$node;
  # -10, means -10 to +infty
  # -10,0 means in fact -10,-1
  # ,10, means -infty to 10,
  # 0,10 means 1,10
  # ,-10 means -infty to -10
  # N,M with N=M=0 or M<N is never satisfied
  return if (defined($min) and defined($max) and $min>$max);
  my $dist=1;
  my $n=$node->rbrother;
  if (defined($min) and $min>$dist) {
    $n = $n->rbrother while ($n and ($dist++)<$min);
  }
  $n=undef if defined($max) and $dist>$max;
  if (!$n) { # try going left
    $dist = -1;
    $n=$node->lbrother;
    if (defined($max) and $max<$dist) {
      $n = $n->lbrother while ($n and ($dist--)>$max);
    }
    $n=undef if defined($min) and $dist<$min;
  }
  $self->[NODE]=$n;
  $self->[DIST]=$dist;
  return ($n && $self->[CONDITIONS]->($n,$fsfile)) ? $n : ($n && $self->next);
}
sub next {
  my ($self)=@_;
  my $conditions=$self->[CONDITIONS];
  my $max = $self->[MAX];
  my $min = $self->[MIN];
  my $dist = $self->[DIST];
  my $fsfile = $self->[FILE];
  my $n=$self->[NODE];
  if ($dist>0) {
    # advance right
    while ($n) {
      $n=$n->rbrother;
      $dist++;
      last if defined($max) and $dist>$max;
      if ($conditions->($n,$fsfile)) {
        $self->[DIST]=$dist;
        return $self->[NODE]=$n;
      }
    }
    # return to start node
    $dist = 0;
    $n=$self->[START];
    if (defined($max) and $max+1<$dist) {
      $n = $n->lbrother while ($n and $max+1<$dist--);
    }
  }
  # advance left
  while ($n) {
    $n=$n->lbrother;
    $dist--;
    last if defined($min) and $dist<$min;
    if ($conditions->($n,$fsfile)) {
      $self->[DIST]=$dist;
      return $self->[NODE]=$n;
    }
  }
  $self->[DIST]=0;
  return $_[0]->[NODE]=undef;
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
  $self->[DIST]=0;
}

1; # End of PMLTQ::Relation::SiblingIteratorWithDistance

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::SiblingIteratorWithDistance - Iterates over siblings given node with boudaries

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
