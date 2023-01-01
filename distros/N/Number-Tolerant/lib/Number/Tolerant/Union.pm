use strict;
use warnings;
package Number::Tolerant::Union 1.710;
# ABSTRACT: unions of tolerance ranges

#pod =head1 SYNOPSIS
#pod
#pod  use Number::Tolerant;
#pod
#pod  my $range1 = tolerance(10 => to => 12);
#pod  my $range2 = tolerance(14 => to => 16);
#pod
#pod  my $union = $range1 | $range2;
#pod
#pod  if ($11 == $union) { ... } # this will happen
#pod  if ($12 == $union) { ... } # so will this
#pod
#pod  if ($13 == $union) { ... } # nothing will happen here
#pod
#pod  if ($14 == $union) { ... } # this will happen
#pod  if ($15 == $union) { ... } # so will this
#pod
#pod =head1 DESCRIPTION
#pod
#pod Number::Tolerant::Union is used by L<Number::Tolerant> to represent the union
#pod of multiple tolerances.  A subset of the same operators that function on a
#pod tolerance will function on a union of tolerances, as listed below.
#pod
#pod =head1 METHODS
#pod
#pod =head2 new
#pod
#pod   my $union = Number::Tolerant::Union->new(@list_of_tolerances);
#pod
#pod There is a C<new> method on the Number::Tolerant::Union class, but unions are
#pod meant to be created with the C<|> operator on a Number::Tolerant tolerance.
#pod
#pod The arguments to C<new> are a list of numbers or tolerances to be unioned.
#pod
#pod Intersecting ranges are not converted into a single range, but this may change
#pod in the future.  (For example, the union of "5 to 10" and "7 to 12" is not "5 to
#pod 12.")
#pod
#pod =cut

sub new {
  my $class = shift;
  bless { options => [ @_ ] } => $class;
}

#pod =head2 options
#pod
#pod This method will return a list of all the acceptable options for the union.
#pod
#pod =cut

sub options {
  my $self = shift;
  return @{$self->{options}};
}

#pod =head2 Overloading
#pod
#pod Tolerance unions overload a few operations, mostly comparisons.
#pod
#pod =over
#pod
#pod =item numification
#pod
#pod Unions numify to undef.  If there's a better idea, I'd love to hear it.
#pod
#pod =item stringification
#pod
#pod A tolerance stringifies to a short description of itself.  This is a set of the
#pod union's options, parentheses-enclosed and joined by the word "or"
#pod
#pod =item equality
#pod
#pod A number is equal to a union if it is equal to any of its options.
#pod
#pod =item comparison
#pod
#pod A number is greater than a union if it is greater than all its options.
#pod
#pod A number is less than a union if it is less than all its options.
#pod
#pod =item union intersection
#pod
#pod An intersection (C<&>) with a union is commutted across all options.  In other
#pod words:
#pod
#pod  (a | b | c) & d  ==yields==> ((a & d) | (b & d) | (c & d))
#pod
#pod Options that have no intersection with the new element are dropped.  The
#pod intersection of a constant number and a union yields that number, if the number
#pod was in the union's ranges and otherwise yields nothing.
#pod
#pod =back
#pod
#pod =cut

use overload
  '0+' => sub { undef },
  '""' => sub { join(' or ', map { "($_)" } $_[0]->options) },
  '==' => sub { for ($_[0]->options) { return 1 if $_ == $_[1] } return 0 },
  '!=' => sub { for ($_[0]->options) { return 0 if $_ == $_[1] } return 1 },
  '>'  =>
    sub {
      if ($_[2]) { for ($_[0]->options) { return 0 unless $_[1] > $_ } return 1 }
      else       { for ($_[0]->options) { return 0 unless $_[1] < $_ } return 1 }
    },
  '<'  =>
    sub {
      if ($_[2]) { for ($_[0]->options) { return 0 unless $_[1] < $_ } return 1 }
      else       { for ($_[0]->options) { return 0 unless $_[1] > $_ } return 1 }
    },
  '<=>' =>
    sub {
      if ($_[2]) { $_[0] < $_[1] ? 1 : $_[0] > $_[1] ? -1 : 0 }
      else       { $_[0] > $_[1] ? 1 : $_[0] < $_[1] ? -1 : 0 }
    },
  '|' => sub { __PACKAGE__->new($_[0]->options,$_[1]); },
  '&' => sub {
    eval { $_[1]->isa('Number::Tolerant') }
      ? __PACKAGE__->new(map { $_ & $_[1] } $_[0]->options )
      : $_[1] == $_[0]
        ? $_[1]
        : ();
    },
  fallback => 1;

#pod =head1 TODO
#pod
#pod Who knows.  Collapsing overlapping options, probably.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Union - unions of tolerance ranges

=head1 VERSION

version 1.710

=head1 SYNOPSIS

 use Number::Tolerant;

 my $range1 = tolerance(10 => to => 12);
 my $range2 = tolerance(14 => to => 16);

 my $union = $range1 | $range2;

 if ($11 == $union) { ... } # this will happen
 if ($12 == $union) { ... } # so will this

 if ($13 == $union) { ... } # nothing will happen here

 if ($14 == $union) { ... } # this will happen
 if ($15 == $union) { ... } # so will this

=head1 DESCRIPTION

Number::Tolerant::Union is used by L<Number::Tolerant> to represent the union
of multiple tolerances.  A subset of the same operators that function on a
tolerance will function on a union of tolerances, as listed below.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $union = Number::Tolerant::Union->new(@list_of_tolerances);

There is a C<new> method on the Number::Tolerant::Union class, but unions are
meant to be created with the C<|> operator on a Number::Tolerant tolerance.

The arguments to C<new> are a list of numbers or tolerances to be unioned.

Intersecting ranges are not converted into a single range, but this may change
in the future.  (For example, the union of "5 to 10" and "7 to 12" is not "5 to
12.")

=head2 options

This method will return a list of all the acceptable options for the union.

=head2 Overloading

Tolerance unions overload a few operations, mostly comparisons.

=over

=item numification

Unions numify to undef.  If there's a better idea, I'd love to hear it.

=item stringification

A tolerance stringifies to a short description of itself.  This is a set of the
union's options, parentheses-enclosed and joined by the word "or"

=item equality

A number is equal to a union if it is equal to any of its options.

=item comparison

A number is greater than a union if it is greater than all its options.

A number is less than a union if it is less than all its options.

=item union intersection

An intersection (C<&>) with a union is commutted across all options.  In other
words:

 (a | b | c) & d  ==yields==> ((a & d) | (b & d) | (c & d))

Options that have no intersection with the new element are dropped.  The
intersection of a constant number and a union yields that number, if the number
was in the union's ranges and otherwise yields nothing.

=back

=head1 TODO

Who knows.  Collapsing overlapping options, probably.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
