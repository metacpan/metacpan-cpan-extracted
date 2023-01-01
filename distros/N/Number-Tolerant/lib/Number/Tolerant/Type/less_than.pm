use strict;
use warnings;
# ABSTRACT: a tolerance "m < n"

package
  Number::Tolerant::Type::less_than;
use parent qw(Number::Tolerant::Type);

sub construct { shift; { value => $_[0], max => $_[0], exclude_max => 1 } }

sub parse {
  my ($self, $string, $factory) = @_;

  my $number = $self->number_re;
  my $X = $self->variable_re;
  return $factory->new(less_than => "$1") if $string =~ m!\A$X?<\s*($number)\z!;
  return $factory->new(less_than => "$1") if $string =~ m!\A($number)\s*>$X\z!;

  return $factory->new(less_than => "$1")
    if $string =~ m!\Aless\s+than\s+($number)\z!;

  return;
}

sub valid_args {
  my $self = shift;

  return unless 2 == grep { defined } @_;

  for my $i ( [0,1], [1,0] ) {
    if (
      $_[ $i->[0] ] eq 'less_than'
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

Number::Tolerant::Type::less_than - a tolerance "m < n"

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
