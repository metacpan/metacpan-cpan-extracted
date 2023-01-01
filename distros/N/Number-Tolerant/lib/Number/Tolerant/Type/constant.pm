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

version 1.710

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
