package PMLTQ::Relation::DescendantIteratorWithBoundedDepth;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::DescendantIteratorWithBoundedDepth::VERSION = '3.0.2';
# ABSTRACT: Iterates over descendant nodes in given boundaries

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use Carp;
use constant CONDITIONS=>0;
use constant MIN=>1;
use constant MAX=>2;
use constant DEPTH=>3;
use constant NODE=>4;
use constant FILE=>5;

sub new {
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
  my ($self,$parent,$fsfile)=@_;
  $self->[FILE]=$fsfile;
  my $n=$parent->firstson;
  $self->[DEPTH]=1;
  $self->[NODE]=$n;
  return ($self->[MIN]<=1 and $self->[CONDITIONS]->($n,$fsfile)) ? $n : ($n && $self->next);
}
sub next {
  my ($self)=@_;
  my $min = $self->[MIN];
  my $max = $self->[MAX];
  my $depth = $self->[DEPTH];
  my $conditions=$self->[CONDITIONS];
  my $n = $self->[NODE];
  my $fsfile=$self->[FILE];
  my $r;
  SEARCH:
  while ($n) {
    if ((!defined($max) or ($depth<$max)) and $n->firstson) {
      $n=$n->firstson;
      $depth++;
    } else {
      while ($n) {
        if ($depth == 0) {
          undef $n;
          last SEARCH;
        }
        if ($r = $n->rbrother) {
          $n=$r;
          last;
        } else {
          $n=$n->parent;
          $depth--;
        }
      }
    }
    if ($n and $min<=$depth and $conditions->($n,$fsfile)) {
      $self->[DEPTH]=$depth;
      return $self->[NODE]=$n;
    }
  }
  return $self->[NODE]=undef;
}
sub file {
  return $_[0]->[FILE];
}
sub node {
  return $_[0]->[NODE];
}
sub reset {
  my ($self)=@_;
  $self->[NODE]=undef;
  $self->[FILE]=undef;
}

1; # End of PMLTQ::Relation::DescendantIteratorWithBoundedDepth

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::DescendantIteratorWithBoundedDepth - Iterates over descendant nodes in given boundaries

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
