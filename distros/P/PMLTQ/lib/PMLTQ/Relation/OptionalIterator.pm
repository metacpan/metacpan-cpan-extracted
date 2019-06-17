package PMLTQ::Relation::OptionalIterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::OptionalIterator::VERSION = '3.0.2';
# ABSTRACT: Creates optional interator branch

use 5.006;
use strict;
use warnings;

use base qw(PMLTQ::Relation::Iterator);
use constant CONDITIONS=>0;
use constant ITERATOR=>1;
use constant NODE=>2;
use constant FILE=>3;
use Carp;

sub new {
  my ($class,$iterator)=@_;
  croak "usage: $class->new(\$iterator)" unless UNIVERSAL::DOES::does($iterator,'PMLTQ::Relation::Iterator');
  return bless [$iterator->conditions,$iterator],$class;
}
sub clone {
  my ($self)=@_;
  return bless [$self->[CONDITIONS],$self->[ITERATOR]], ref($self);
}
sub start  {
  my ($self,$parent,$fsfile)=@_;
  $self->[NODE]=$parent;
  $self->[FILE]=$fsfile;
  return $parent ? ($self->[CONDITIONS]->($parent,$fsfile) ? $parent : $self->next) : undef;
}
sub next {
  my ($self)=@_;
  my $n = $self->[NODE];
  if ($n) {
    $self->[NODE]=undef;
    return $self->[ITERATOR]->start($n,$self->[FILE]);
  }
  return $self->[ITERATOR]->next;
}
sub node {
  my ($self)=@_;
  return $self->[NODE] || $self->[ITERATOR]->node;
}
sub file {
  return $_[0]->[FILE];
}
sub reset {
  my ($self)=@_;
  $self->[NODE]=undef;
  $self->[FILE]=undef;
  $self->[ITERATOR]->reset;
}

1; # End of PMLTQ::Relation::OptionalIterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::OptionalIterator - Creates optional interator branch

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
