package PMLTQ::Relation::SameTreeIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::SameTreeIterator::VERSION = '3.0.2';
# ABSTRACT: Evaluates condition on nodes of current tree

use 5.006;
use strict;
use warnings;

use Carp;
use base qw(PMLTQ::Relation::TreeIterator);

sub new  {
  my ($class,$conditions)=@_;
  croak "usage: $class->new(sub{...})" unless ref($conditions) eq 'CODE';
  return bless [$conditions],$class;
}
sub start  {
  my ($self,$root,$fsfile)=@_;
  $root=$root->root if $root;
  $self->[PMLTQ::Relation::TreeIterator::NODE] = $self->[PMLTQ::Relation::TreeIterator::TREE] = $root;
  $self->[PMLTQ::Relation::TreeIterator::FILE]=$fsfile;
  return ($root && $self->[PMLTQ::Relation::TreeIterator::CONDITIONS]->($root,$fsfile)) ? $root : ($root && $self->next);
}

1; # End of PMLTQ::Relation::SameTreeIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::SameTreeIterator - Evaluates condition on nodes of current tree

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
