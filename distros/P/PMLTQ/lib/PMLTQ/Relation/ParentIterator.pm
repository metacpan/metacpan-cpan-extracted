package PMLTQ::Relation::ParentIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::ParentIterator::VERSION = '3.0.2';
# ABSTRACT: Evaluates condition on the parent of start node 

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use constant CONDITIONS=>0;
use constant NODE=>1;
use constant FILE=>2;

sub start  {
  my ($self,$node,$fsfile)=@_;
  $self->[FILE]=$fsfile;
  my $n = $node->parent;
  return $self->[NODE] = ($n && $self->[CONDITIONS]->($n,$fsfile)) ? $n : undef;
}
sub next {
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
}

1; # End of PMLTQ::Relation::ParentIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::ParentIterator - Evaluates condition on the parent of start node 

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
