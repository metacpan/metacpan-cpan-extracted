use strict;
use warnings;
# ABSTRACT: a tolerance "m to n"

package
  Number::Tolerant::Type::to;
use parent qw(Number::Tolerant::Type);

sub construct { shift;
  ($_[0],$_[1]) = sort { $a <=> $b } ($_[0],$_[1]);
  {
    value    => ($_[0]+$_[1])/2,
    variance => $_[1] - ($_[0]+$_[1])/2,
    min      => $_[0],
    max      => $_[1]
  }
}

sub parse {
  my ($self, $string, $factory) = @_;
  my $number = $self->number_re;
  my $X = $self->variable_re;

  return $factory->new("$1", 'to', "$2")
    if ($string =~ m!\A($number)\s*<=$X<=\s*($number)\z!);
  return $factory->new("$2", 'to', "$1")
    if ($string =~ m!\A($number)\s*>=$X>=\s*($number)\z!);
  return $factory->new("$1", 'to', "$2")
    if ($string =~ m!\A($number)\s+to\s+($number)\z!);
  return;
}

sub valid_args {
  my $self = shift;

  return unless 3 == grep { defined } @_;
  return unless $_[1] eq 'to';

  return unless defined (my $from = $self->normalize_number($_[0]));
  return unless defined (my $to   = $self->normalize_number($_[2]));

  return ($from, $to);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Type::to - a tolerance "m to n"

=head1 VERSION

version 1.708

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
