use strict;
use warnings;
# ABSTRACT: a tolerance "m +/- n%"

package
  Number::Tolerant::Type::plus_or_minus_pct;
use parent qw(Number::Tolerant::Type);

sub construct { shift;
  {
    value    => $_[0],
    variance => $_[1],
    min      => $_[0] - $_[0]*($_[1]/100),
    max      => $_[0] + $_[0]*($_[1]/100)
  }
}

sub parse {
  my ($self, $string, $factory) = @_;
  my $number = $self->number_re;

  return $factory->new("$1", 'plus_or_minus_pct', "$2")
    if $string =~ m!\A($number)\s*\+/-\s*($number)%\z!;
  return;
}

sub stringify { "$_[0]->{value} +/- $_[0]->{variance}%" }

sub valid_args {
  my $self = shift;

  return unless 3 == grep { defined } @_;
  return unless $_[1] eq 'plus_or_minus_pct';

  return unless defined (my $base = $self->normalize_number($_[0]));
  return unless defined (my $var  = $self->normalize_number($_[2]));

  return ($base, $var);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Type::plus_or_minus_pct - a tolerance "m +/- n%"

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
