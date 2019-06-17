package PMLTQ::Relation::MemberIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::MemberIterator::VERSION = '3.0.2';
# ABSTRACT: Iterates over member nodes of given list

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::SimpleListIterator);
use constant ATTR => PMLTQ::Relation::SimpleListIterator::FIRST_FREE;
use Carp;

sub new {
  my ($class,$conditions,$attr)=@_;
  croak "usage: $class->new(sub{...},\$attr)" unless (ref($conditions) eq 'CODE' and defined $attr);
  my $self = PMLTQ::Relation::SimpleListIterator->new($conditions);
  $self->[ATTR]=$attr;
  bless $self, $class; # reblessing
  return $self;
}
sub clone {
  my ($self)=@_;
  my $clone = $self->PMLTQ::Relation::SimpleListIterator::clone();
  $clone->[ATTR]=$self->[ATTR];
  return $clone;
}
sub get_node_list  {
  my ($self,$node)=@_;
  my $fsfile = $self->[PMLTQ::Relation::SimpleListIterator::FILE];
  #print STDERR "MemberIterator attr: $self->[ATTR]\n";
  return [map [$_,$fsfile], Treex::PML::Instance::get_all($node,$self->[ATTR])];

}

1; # End of PMLTQ::Relation::MemberIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::MemberIterator - Iterates over member nodes of given list

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
