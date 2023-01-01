use strict;
use warnings;
# ABSTRACT: a tolerance "m (-l or +n)"

package
  Number::Tolerant::Type::offset;
use parent qw(Number::Tolerant::Type);

sub construct { shift;
  {
    value => $_[0],
    min   => $_[0] + $_[1],
    max   => $_[0] + $_[2]
  }
}

sub parse {
  my ($self, $string, $factory) = @_;

  my $number = $self->number_re;
  return $factory->new("$1", 'offset', "$2", "$3")
    if $string =~ m!\A($number)\s+\(?\s*($number)\s+($number)\s*\)?\s*\z!;

  return;
}

sub stringify {
  my ($self) = @_;
  return sprintf "%s (-%s +%s)",
    $_[0]->{value},
    ($_[0]->{value} - $_[0]->{min}),
    ($_[0]->{max} - $_[0]->{value});
}

sub valid_args {
  my $self = shift;

  return if @_ > 4;

  return unless defined(my $lhs_number   = $self->normalize_number($_[0]));
  return unless defined(my $minus_number = $self->normalize_number($_[2]));
  return unless defined(my $plus_number  = $self->normalize_number($_[3]));

  return unless $_[1] eq 'offset';
  return unless $minus_number <= 0;
  return unless $plus_number  >= 0;

  return ($lhs_number, $minus_number, $plus_number)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Type::offset - a tolerance "m (-l or +n)"

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
