use strict;
use warnings;
# ABSTRACT: a tolerance "m > n"

package
  Number::Tolerant::Type::more_than;
use parent qw(Number::Tolerant::Type);

sub construct { shift; { value => $_[0], min => $_[0], exclude_min => 1 } }

sub parse {
  my ($self, $string, $factory) = @_;

  my $number = $self->number_re;
  my $X = $self->variable_re;

  return $factory->new(more_than => "$1") if $string =~ m!\A($number)\s*<$X\z!;
  return $factory->new(more_than => "$1") if $string =~ m!\A$X?>\s*($number)\z!;

  return $factory->new(more_than => "$1")
    if $string =~ m!\Amore\s+than\s+($number)\z!;
  return;
}

sub valid_args {
  my $self = shift;

  return unless 2 == grep { defined } @_;

  for my $i ( [0,1], [1,0] ) {
    if (
      $_[ $i->[0] ] eq 'more_than'
      and defined (my $num = $self->normalize_number($_[ $i->[1] ]))
    ) {
      return $num;
    }
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Type::more_than - a tolerance "m > n"

=head1 VERSION

version 1.708

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
