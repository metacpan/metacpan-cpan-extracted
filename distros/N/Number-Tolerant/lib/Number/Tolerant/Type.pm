use strict;
use warnings;
package Number::Tolerant::Type 1.710;
# ABSTRACT: a type of tolerance

use parent qw(Number::Tolerant);
use Math::BigFloat;
use Math::BigRat;

#pod =head1 SYNOPSIS
#pod
#pod =cut

#pod =head1 METHODS
#pod
#pod =head2 valid_args
#pod
#pod   my @args = $type_class->valid_args(@_);
#pod
#pod If the arguments to C<valid_args> are valid arguments for this type of
#pod tolerance, this method returns their canonical form, suitable for passing to
#pod C<L</construct>>.  Otherwise this method returns false.
#pod
#pod =head2 construct
#pod
#pod   my $object_guts = $type_class->construct(@args);
#pod
#pod This method is passed the output of the C<L</valid_args>> method, and should
#pod return a hashref that will become the guts of a new tolerance.
#pod
#pod =head2 parse
#pod
#pod   my $tolerance = $type_class->parse($string);
#pod
#pod This method returns a new, fully constructed tolerance from the given string
#pod if the given string can be parsed into a tolerance of this type.
#pod
#pod =head2 number_re
#pod
#pod   my $number_re = $type_class->number_re;
#pod
#pod This method returns the regular expression (as a C<qx> construct) used to match
#pod number in parsed strings.
#pod
#pod =head2 normalize_number
#pod
#pod   my $number = $type_class->normalize_number($input);
#pod
#pod This method will decide whether the given input is a valid number for use with
#pod Number::Tolerant and return it in a canonicalized form.  Math::BigInt objects
#pod are returned intact.  Strings holding numbers are also returned intact.
#pod Strings that appears to be fractions are converted to Math::BigRat objects.
#pod
#pod Anything else is considered invalid, and the method will return false.
#pod
#pod =cut

my $number;
BEGIN {
  $number = qr{
    (?:
      (?:[+-]?)
      (?=[0-9]|\.[0-9])
      [0-9]*
      (?:\.[0-9]*)?
      (?:[Ee](?:[+-]?[0-9]+))?
    )
    |
    (?:
      [0-9]+ / [1-9][0-9]*
    )
  }x;
}

sub number_re { return $number; }

sub normalize_number {
  my ($self, $input) = @_;

  return if not defined $input;

  if ($input =~ qr{\A$number\z}) {
    return $input =~ m{/} ? Math::BigRat->new($input) : $input;
    # my $class = $input =~ m{/} ? 'Math::BigRat' : 'Math::BigRat';
    # return $class->new($input);
  }

  local $@;
  return $input if ref $input and eval { $input->isa('Math::BigInt') };

  return;
}

#pod =head2 variable_re
#pod
#pod   my $variable_re = $type_class->variable_re;
#pod
#pod This method returns the regular expression (as a C<qr> construct) used to match
#pod the variable in parsed strings.
#pod
#pod When parsing "4 <= x <= 10" this regular expression is used to match the letter
#pod "x."
#pod
#pod =cut

my $X;
BEGIN { $X =  qr/(?:\s*x\s*)/; }

sub variable_re { return $X; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Tolerant::Type - a type of tolerance

=head1 VERSION

version 1.710

=head1 SYNOPSIS

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 valid_args

  my @args = $type_class->valid_args(@_);

If the arguments to C<valid_args> are valid arguments for this type of
tolerance, this method returns their canonical form, suitable for passing to
C<L</construct>>.  Otherwise this method returns false.

=head2 construct

  my $object_guts = $type_class->construct(@args);

This method is passed the output of the C<L</valid_args>> method, and should
return a hashref that will become the guts of a new tolerance.

=head2 parse

  my $tolerance = $type_class->parse($string);

This method returns a new, fully constructed tolerance from the given string
if the given string can be parsed into a tolerance of this type.

=head2 number_re

  my $number_re = $type_class->number_re;

This method returns the regular expression (as a C<qx> construct) used to match
number in parsed strings.

=head2 normalize_number

  my $number = $type_class->normalize_number($input);

This method will decide whether the given input is a valid number for use with
Number::Tolerant and return it in a canonicalized form.  Math::BigInt objects
are returned intact.  Strings holding numbers are also returned intact.
Strings that appears to be fractions are converted to Math::BigRat objects.

Anything else is considered invalid, and the method will return false.

=head2 variable_re

  my $variable_re = $type_class->variable_re;

This method returns the regular expression (as a C<qr> construct) used to match
the variable in parsed strings.

When parsing "4 <= x <= 10" this regular expression is used to match the letter
"x."

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
