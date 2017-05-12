use strict;
use warnings;
# ABSTRACT: a tolerance "m >= n"

package
  Number::Tolerant::Type::or_more;
use parent qw(Number::Tolerant::Type);

sub construct { shift; { value => $_[0], min => $_[0] } }

sub parse {
  my ($self, $string, $factory) = @_;
  my $number = $self->number_re;
  my $X = $self->variable_re;

  return $factory->new("$1", 'or_more') if $string =~ m!\A($number)\s*<=$X\z!;
  return $factory->new("$1", 'or_more') if $string =~ m!\A$X?>=\s*($number)\z!;
  return $factory->new("$1", 'or_more')
    if $string =~ m!\A($number)\s+or\s+more\z!;

  return;
}

sub valid_args {
  my $self = shift;

  return unless 2 == grep { defined } @_;
  return unless $_[1] eq 'or_more';

  return $self->normalize_number($_[0]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Type::or_more - a tolerance "m >= n"

=head1 VERSION

version 1.708

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
