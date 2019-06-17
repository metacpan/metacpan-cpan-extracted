package PMLTQ::Relation::Iterator;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Relation::Iterator::VERSION = '3.0.2';
# ABSTRACT: Base Iterator class

use 5.006;
use strict;
use warnings;

use constant CONDITIONS=>0;
use Carp;

sub new {
  my ($class,$conditions)=@_;
  croak "usage: $class->new(sub{...})" unless ref($conditions) eq 'CODE';
  return bless [$conditions],$class;
}

sub clone {
  my ($self)=@_;
  return bless [$self->[CONDITIONS]], ref($self);
}

sub conditions { return $_[0]->[CONDITIONS]; }

sub set_conditions { $_[0]->[CONDITIONS]=$_[1]; }

sub start {}

sub next {}

sub node {}

sub reset {}

1; # End of PMLTQ::Relation::Iterator

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Relation::Iterator - Base Iterator class

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
