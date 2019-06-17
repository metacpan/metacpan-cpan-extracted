package PMLTQ::Relation::TransitiveIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::TransitiveIterator::VERSION = '3.0.2';
# ABSTRACT: Iterates over nodes that are transitive

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use constant CONDITIONS=>0;
use constant ITERATOR=>1;
use constant MIN=>2;
use constant MAX=>3;
use constant ITER_STACK=>4;
use constant SEEN=>5;
use constant FILE=>6;
use constant DEPTH=>7;
use constant FOUND=>8;
use Carp;

our $DEBUG; ### newly added

sub new {
  my ($class,$iterator,$min,$max)=@_;
  confess "usage: $class->new(\$iterator,\$min,\$max)" unless UNIVERSAL::DOES::does($iterator,'PMLTQ::Relation::Iterator');
  $min||=1;
  my $conditions = $iterator->conditions;
  $iterator->set_conditions(sub{1});
  warn "blessed $iterator,$min,$max,0.\n" if $DEBUG;
  return bless [$conditions,$iterator,$min,$max,0],$class;
}
sub clone {
  my ($self)=@_;
  return bless [$self->[CONDITIONS],$self->[ITERATOR],$self->[MIN],$self->[MAX]], ref($self);
}
sub start  {
  my ($self,$parent,$fsfile)=@_;
  $self->[FILE]=$fsfile;
  my $conditions = $self->[CONDITIONS];
  my $seen = $self->[SEEN]={};
  my $iter = $self->[ITERATOR]->clone();
  my $iterators = $self->[ITER_STACK]=[ $iter ];
  my $n = $iter->start($parent,$fsfile);
  $seen->{$n}=1;
  $self->[DEPTH] = 1;
  my $found = $self->[FOUND]={};
  warn "START $parent->{id},".($n?$n->{id}:q//).".\n" if $DEBUG;
  $found->{$n}=1 if $conditions->($n, $iter->file);
  return $self->[MIN]<=1 && scalar(keys %$found) > 0 ? $n : $self->next;
}
sub next {
  my ($self)=@_;
  my $depth = $self->[DEPTH];
  my $found = $self->[FOUND];
  return if $depth<1;
  my $seen = $self->[SEEN];
  my $conditions = $self->[CONDITIONS];
  my $iterators = $self->[ITER_STACK];
  my $iter = $iterators->[-1];
  my $min = $self->[MIN];
  my $max = $self->[MAX];
  my $n = $iter->node;
  warn "NEXT: $min,$max: $n->{id} (depth $depth)\n" if $DEBUG;
  while ($n) {
    if (!$max or $depth<$max) {
      # prolong the iteratator (depth first)
      my $new_it = $self->[ITERATOR]->clone();
      my $new_n = $new_it->start($n,$self->[FILE]);
      $new_n = $new_it->next while ($new_n and $seen->{$new_n});
      warn "NEWN $n->{id}" if $DEBUG;
      if ($new_n) {
        push @$iterators, $new_it;
        $n = $new_n;
        $seen->{$n}=1;
        $iter = $new_it;
        $depth ++;
        $found->{$n}=1 if $conditions->($new_n, $new_it->file);
        next if scalar(keys %$found)<$min;
        last;
      }
    }
    # continue top-level iterator (go breadth)
    delete $seen->{$n};
    $n = $iter->next;
    $n = $n->next while ($n and $seen->{$n});
    while (!$n and $depth>1) {
      pop @$iterators; # drop current iterator
      $depth --;
      $iter = $iterators->[-1]; # current top-level iterator
      delete $seen->{ $iter->node };
      delete $found->{ $iter->node };
      $n = $iter->next;
      $n = $n->next while ($n and $seen->{$n});
    }
    $seen->{$n}=1 if $n;
    last unless (scalar(keys %$found)<$min and
                 scalar(keys %$found)>=1); # prolong if found but not long enough
  }
  $self->[DEPTH]=$depth;
  warn 'NEXT RETURN ',$n?$n->{id}:'empty',".\n" if $DEBUG;
  return $n;
}
sub node {
  my ($self)=@_;
  if ($self->[DEPTH]>0) {
    return $self->[ITER_STACK][-1]->node;
  } else {
    return undef;
  }
}
sub file {
  my ($self)=@_;
  if ($self->[DEPTH]>0) {
    return $self->[ITER_STACK][-1]->file;
  } else {
    return undef;
  }
}
sub reset {
  my ($self)=@_;
  $self->[FILE]=undef;
  $self->[ITER_STACK]=undef;
  $self->[DEPTH]=undef;
  $self->[SEEN]=undef;
}

1; # End of PMLTQ::Relation::TransitiveIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::TransitiveIterator - Iterates over nodes that are transitive

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
