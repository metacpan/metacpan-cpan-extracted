package PMLTQ::Relation::OrderIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::OrderIterator::VERSION = '3.0.2';
# ABSTRACT: Interates nodes based on their order

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::SimpleListIterator);
use constant SOURCE_ORD_ATTR => PMLTQ::Relation::SimpleListIterator::FIRST_FREE;
use constant TARGET_ORD_ATTR => PMLTQ::Relation::SimpleListIterator::FIRST_FREE+1;
use constant DIR => PMLTQ::Relation::SimpleListIterator::FIRST_FREE+2;
use constant MIN => PMLTQ::Relation::SimpleListIterator::FIRST_FREE+3;
use constant MAX => PMLTQ::Relation::SimpleListIterator::FIRST_FREE+4;
use constant SPAN_INIT => PMLTQ::Relation::SimpleListIterator::FIRST_FREE+5;
use Carp;

sub new {
  my ($class,$conditions,$s_ord_attr,$t_ord_attr,$dir,$min,$max,$span_init)=@_;
  croak "usage: $class->new(sub{...},\$source_ord_attr,\$target_ord_attr)"
    unless (ref($conditions) eq 'CODE' and defined($s_ord_attr) and defined($t_ord_attr));
  my $self = PMLTQ::Relation::SimpleListIterator->new($conditions);
  $self->[SOURCE_ORD_ATTR]=$s_ord_attr;
  $self->[TARGET_ORD_ATTR]=$t_ord_attr;
  $self->[DIR]=$dir; # dir should be 1 or -1
  $self->[MIN]=$min if defined($min) and length($min);
  $self->[MAX]=$max if defined($max) and length($max);
  $self->[SPAN_INIT]=$span_init if defined($span_init) and ref($span_init);
  bless $self, $class; # reblessing
  return $self;
}
sub clone {
  my ($self)=@_;
  my $clone = $self->PMLTQ::Relation::SimpleListIterator::clone();
  $clone->[SOURCE_ORD_ATTR]=$self->[SOURCE_ORD_ATTR];
  $clone->[TARGET_ORD_ATTR]=$self->[TARGET_ORD_ATTR];
  $clone->[DIR]=$self->[DIR];
  $clone->[MIN]=$self->[MIN];
  $clone->[MAX]=$self->[MAX];
  $clone->[SPAN_INIT]=$self->[SPAN_INIT];
  return $clone;
}
sub get_node_list  {
  my ($self,$node)=@_;
  my $fsfile = $self->[PMLTQ::Relation::SimpleListIterator::FILE];
  my $dir = $self->[DIR];
  my $s_ord_attr = $self->[SOURCE_ORD_ATTR];
  my $t_ord_attr = $self->[TARGET_ORD_ATTR];
  my $min = $self->[MIN];
  my $max = $self->[MAX];
  $min = 0 if !defined($min);
  my $root = $node->root;
  if ((!$s_ord_attr or !$t_ord_attr) and $self->[SPAN_INIT]) {
    $self->[SPAN_INIT]->($root)
  }
  my $s_ord = $s_ord_attr ?
    $node->{$s_ord_attr} :
    $self->[SPAN_INIT]->($node)->[ ($dir>0) ? 0 : 1 ];
  return [] unless defined $s_ord;
  return [map [$_,$fsfile],
          grep {
            my $t_ord = $t_ord_attr ? $_->{$t_ord_attr} : $self->[SPAN_INIT]->($_)->[ ($dir>0) ? 1 : 0 ];
            if (defined $t_ord) {
              my $dist = $dir*($s_ord - $t_ord);
              $_!=$node and (!defined($min) or $dist>=$min) and (!defined($max) or $dist<=$max)
            }
          }
          $root->descendants];
}

1; # End of PMLTQ::Relation::OrderIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::OrderIterator - Interates nodes based on their order

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
