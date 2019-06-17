package PMLTQ::Relation::DepthFirstRangeIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::DepthFirstRangeIterator::VERSION = '3.0.2';
# ABSTRACT: Iterates tree using depth first search in given boundaries


use 5.006;
use strict;
use warnings;

use Carp;
use base qw(PMLTQ::Relation::Iterator);
use constant CONDITIONS=>0;
use constant LMIN =>1;
use constant LMAX =>2;
use constant RMIN =>3;
use constant RMAX =>4;
use constant DIST =>5;
use constant NODE=>6;
use constant FILE=>7;
use constant START=>8;


sub new  {
  my ($class,$conditions,$lmin,$lmax,$rmin,$rmax)=@_;
  croak "usage: $class->new(sub{...})" unless ref($conditions) eq 'CODE';
  return bless [$conditions,$lmin,$lmax,$rmin,$rmax],$class;
}
sub clone {
  my ($self)=@_;
  return bless [$self->[CONDITIONS],$self->[LMIN],$self->[LMAX],$self->[RMIN],$self->[RMAX]], ref($self);
}
sub start  {
  my ($self,$start_node,$fsfile)=@_;
  if ($fsfile) {
    $self->[FILE]=$fsfile;
  } else {
    $fsfile=$self->[FILE];
  }
  $self->[START] = $start_node;
  my $n;
  my $dist=0;
  my $rmin = $self->[RMIN];
  if (defined($rmin)) {
    $n=$start_node;
    while ($n and $dist<$rmin) {
      $n = $n->following;
      $dist++;
    }
    my $rmax = $self->[RMAX];
    undef $n if ($n and defined($rmax) and $dist>$rmax);
  }
  if (!$n) {
    my $lmin = $self->[LMIN];
    if (defined($lmin)) {
      $dist=0;
      $n=$start_node;
      while ($n and $dist>$lmin) {
        $n = $n->previous;
        $dist--;
      }
      my $lmax = $self->[LMAX];
      undef $n if ($n and defined($lmax) and $dist<$lmax);
    }
  }
  $self->[DIST]=$dist;
  $self->[NODE]=$n;
  return ($n && $self->[CONDITIONS]->($n,$fsfile)) ? $n : ($n && $self->next);
}
sub next {
  my ($self)=@_;
  my $conditions=$self->[CONDITIONS];
  my $n=$self->[NODE];
  my $fsfile=$self->[FILE];
  my $dist=$self->[DIST];

  my $max;
  if ($dist>0) {
    # advance right
    $max=$self->[RMAX];
    while ($n) {
      $dist++;
      last if (defined($max) and $dist>$max);
      $n=$n->following();
      if ($conditions->($n,$fsfile)) {
        $self->[DIST]=$dist;
        return $self->[NODE]=$n;
      }
    }
    my $lmin = $self->[LMIN];
    unless (defined $lmin) {
      $self->[DIST]=$dist;
      return($self->[NODE]=undef);
    }
    $dist = 0;
    $n = $self->[START];
    while ($n and ($dist-1) > $lmin) {
      $n = $n->previous;
      $dist--;
    }
  }
  # advance left
  $max = $self->[LMAX];
  while ($n) {
    $dist--;
    if (defined($max) and $dist<$max) {
      undef $n;
      last;
    }
    $n=$n->previous();
    last if $conditions->($n,$fsfile);
  }
  $self->[DIST]=$dist;
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
  $self->[START]=undef;
  $self->[DIST]=undef;
}

1; # End of PMLTQ::Relation::DepthFirstRangeIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::DepthFirstRangeIterator - Iterates tree using depth first search in given boundaries

=head1 VERSION

version 3.0.2

=head1 SYNOPSIS

This iterator returns nodes preceding the start node if their depth-first-
order distance from it falls into the range [-LMAX,-LMIN] and following the
start node in their depth-first-order distance from it falls into the range
[RMIN,RMAX]; note that the arguments for LMIN,LMAX must be negative values.
For example, given (LMIN,LMAX,RMIN,RMAX) = (-1,-3,1,4), the iterator returns
first three nodes preceding and first four nodes following the start node

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
