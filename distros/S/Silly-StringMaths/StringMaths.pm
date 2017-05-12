package Silly::StringMaths;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK @EXPORT);
@ISA=qw(Exporter);
@EXPORT=();
@EXPORT_OK=qw(add subtract multiply divide exponentiate
				  normalise sign negative invert);

$VERSION = '0.13';

=head1 NAME

Silly::StringMaths - Perl extension for doing maths with strings

=head1 SYNOPSIS

  use Silly::StringMaths qw(add subtract multiply divide exponentiate);

  # Add two positive numbers - returns ABFOOR
  print add("FOO", "BAR");

  # Add a generally positive number and a negative number
  # - returns ot
  print add("FNoRD", "yncft");

  # Subtract several numbers from a rather large one
  # - returns accdeiiiiloopssu
  print subtract("Supercalifragilisticepsialidocious",
					  "stupid", "made", "up", "word");

  # Multiply two negative numbers - returns AAACCCCCCEEELLLNNN
  print multiply("cancel", "out");

  # Divide two numbers - returns AAA
  print divide("EuropeanCommission", "France");

  # Confirm Pythagorus' theorum - returns nothing
  print subtract(exponentiate("FETLA", "PI"),
					  exponentiate("TLA", "PI"),
					  exponentiate("ETLA", "PI"));

=head1 DESCRIPTION

Silly::StringMaths provides support for basic integer mathematics, using
strings rather than numbers. Upper-case letters are positive,
lower-case letters are negative, so ABCDEF would be 6 (but
WOMBAT would also be 6), whereas C<positive> would actually be
-8. Mixed-case is also possible, so Compaq is actually -5.
Most methods return a canonicalised version of the string -
e.g. C<ampq> rather than C<Compaq> (mixed case removed,
the result sorted alphabetically).

The behaviour of other characters is as yet undefined, but be
warned that non-alphabetical characters may be reserved for
floating point or imaginary numbers.

Actual numbers (i.e. the characters 0 to 9) will I<never> be used
by this module.

=head1 BASIC METHODS

=head2 add

Takes an array of strings, returns the sum.

=cut

sub add {
	my $base=shift;
	# Go through our arguments in turn
	while (my $addition=shift) {
		# If there are any positive elements, add them on now
		while ($addition =~ s/([A-Z])//) {
			$base.=$1;
		}
		# If there are any negative elements, subtract:
		while ($addition =~ s/([a-z])//) {
			# First take away any positive letters
			if ($base =~ /[A-Z]/) {
				$base =~ s/[A-Z]//;
			} else {
				# Then add on negative ones
				$base.=$1;
			}
		}
	}
	# Return a normalised (i.e. sorted and condensed) version of this
	return Silly::StringMaths::normalise($base);
}

=head2 subtract

Takes a string, subtracts all other supplied strings from it and
returns the result.

=cut

sub subtract {
	my ($base, @others)=@_;
	# Find our base, subtract all other numbers by adding negative
	# versions of them
	foreach (@others) {
		Silly::StringMaths::invert(\$_);
	}
	return Silly::StringMaths::add($base, @others);
}

=head2 multiply

Takes a string and multiplies it by all the other strings,
returning the resulting product.

=cut

sub multiply {
	# Find our base number, normalise it
	my $base=Silly::StringMaths::normalise(shift);
	while (my $product=Silly::StringMaths::normalise(shift)) {
		# If the argument is negative, invert the base number
		if (Silly::StringMaths::negative($product)) {
			Silly::StringMaths::invert(\$base);
		}
		# Now add on the base number as many times as we have extra letters
		# (so remove one letter from the product first)
		$product =~ s%.%%;
		my $step=$base;
		while ($product =~ s%.%%) {
			$base=Silly::StringMaths::add($base, $step);
		}
	}
	return $base;
}

=head2 divide

Takes a string, and divides it by all the other strings,
returning the result. Results are rounded down.

=cut

sub divide {
	# Find our base number, normalise it
	my $base=Silly::StringMaths::normalise(shift);
	# Find the sign of this number, convert the base number to positive
	my $sign=Silly::StringMaths::sign($base);
	if (Silly::StringMaths::negative($sign)) {
		$base=Silly::StringMaths::multiply($base, $sign);
	}
	# Step through our divisors
	while (my $divisor=Silly::StringMaths::normalise(shift)) {
		# If this divisor is negative, invert our sign
		if (Silly::StringMaths::negative(Silly::StringMaths::sign($divisor))) {
			Silly::StringMaths::invert(\$sign);
			Silly::StringMaths::invert(\$divisor);
		}
		# Now find how many times we can remove our divisor
		# First convert our divisor to a regexp that can remove itself from
		# a number, then apply it as many times as possible, and insert
		# that many As into the return value
		$divisor =~ s%.%.%g;
		$base="A"x($base =~ s%$divisor%%g);
	}
	# Multiply our (positive) base number by the stored sign, return it
	return Silly::StringMaths::multiply($base, $sign);
}

=head2 exponentiate

Takes a number, raises it to the appropriate power, as specified by the
other arguments. Returns the result. (Note that some textual information
is lost here - the result will be either C<A>s or C<a>s).

=cut

sub exponentiate {
	my $base=Silly::StringMaths::normalise(shift);
	while (my $power=Silly::StringMaths::normalise(shift)) {
		# Don't allow negative powers
		if (Silly::StringMaths::negative($power)) {
			warn "Cannot use negative power $power";
			return undef;
		}
		# Find the number we multiply by (the original base number)
		my $multiply=$base;
		# Remove one 
		$power =~ s%.%%;
		# For every remaining digit, multiply base by its original value
		while ($power =~ s%.%%) {
			$base=Silly::StringMaths::multiply($base, $multiply);
		}
	}
	return $base;
}

=head1 USEFUL TOOLBOX METHODS

=head2 normalise

Takes a string with, potentially, a mix of upper-case and lower-case
letters, and returns a sorted string that is unmistakeably either
positive or negative.

=cut

sub normalise {
	my ($number)=@_;

	# If there's a mixture of upper and lower case, add this number to
	# a null string to make the negatives and positives cancel out
	if ($number =~ /[A-Z]/ && $number =~ /[a-z]/) {
		$number=Silly::StringMaths::add(undef, $number);
	}
	# Return this string in sorted form
	return join("", sort split("", $number));
}

=head2 sign

Returns the sign of a number as either 1, 0 or -1 (as a string,
obviously).

=cut

sub sign {
	# Take the sign of a number by normalising it, then removing all but
	# the first character, so we have 1 or -1
	my $number=Silly::StringMaths::normalise(shift);
	$number =~ s%^(.).*%$1%;
	return $number;
}

=head2 negative

Returns whether the supplied string is negative or not

=cut

sub negative {
	my ($number)=@_;
	return (Silly::StringMaths::normalise($number) =~ /[a-z]/);
}

=head2 invert

Takes a I<reference> to a number, inverts it.

=cut

sub invert {
	my ($number)=shift;
	$$number = Silly::StringMaths::normalise($$number);
	$$number =~ tr/A-Za-z/a-zA-Z/;
	return $$number;
}


=head1 AUTHOR

Sam Kington, sam@illuminated.co.uk

=head1 SEE ALSO

perl(1).

=cut


1;

