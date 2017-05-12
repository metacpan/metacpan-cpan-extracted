use strict;
use warnings;
# ABSTRACT: a tolerance "m == n"

package
  Number::Tolerant::Type::constant;
use parent qw(Number::Tolerant::Type);

sub construct { shift; $_[0] }

sub parse {
  my $self = shift;
  return $self->normalize_number($_[0]);
}

sub valid_args {
  my $self = shift;

  my $number = $self->normalize_number($_[0]);

  return unless defined $number;

  return $number if @_ == 1;

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Type::constant - a tolerance "m == n"

=head1 VERSION

version 1.708

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
