package Number::Natural::SetTheory;

use 5.010;
use boolean;
use JSON qw/to_json/;
use strict;
use utf8;

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN
{
	$Number::Natural::SetTheory::AUTHORITY = 'cpan:TOBYINK';
	$Number::Natural::SetTheory::VERSION   = '0.004';
	
	@EXPORT    = qw/ /;
	@EXPORT_OK = qw/ set_is_number set_to_number number_to_set set_to_string /;
	$EXPORT_TAGS{'all'} = \@EXPORT_OK;
	$EXPORT_TAGS{'default'} = $EXPORT_TAGS{'standard'} = \@EXPORT;
}

use base qw/Exporter/;

sub set_is_number
{
	my ($set, $number) = @_;
	return undef unless int($number)==$number;
	
	if (!ref $set and $set =~ /^\d+$/ and int($set)==$set)
	{
		return ($set==$number) ? true : false;
	}

	return undef unless ref $set eq 'ARRAY';
	
	my $count = scalar @$set;
	
	return false
		if ($count != $number);
	
	return true
		if ($count == 0);

	my %accounted_for = map { $_ => false } 0..($count - 1);
	
	foreach my $member (@$set)
	{
		my $number = set_to_number($member);
		
		if (defined $number and exists $accounted_for{$number})
		{
			if ($accounted_for{$number})
			{
				return false;
			}
			elsif (not $accounted_for{$number})
			{
				$accounted_for{$number} = true;
			}
		}
	}
	
	if (grep { !$_ } values %accounted_for)
	{
		return false;
	}
	
	return true;
}

sub number_to_set
{
	my ($num) = @_;
	
	unless ($num =~ /^\d+$/ and int($num)==$num)
	{
		return undef;
	}
	
	return [] if $num==0;
	my @set = map { number_to_set($_) } 0 .. ($num-1);
	return \@set;
}

sub set_to_number
{
	my ($set) = @_;
	
	if (!ref $set and $set =~ /^\d+$/ and int($set)==$set)
	{
		return $set;
	}
	
	return undef unless ref $set eq 'ARRAY';
	
	if (set_is_number($set, scalar @$set))
	{
		return scalar @$set;
	}
	
	return undef;
}

sub set_to_string
{
	my ($set) = @_;
	my $string = to_json($set);
	$string =~ s/\[/\{/g;
	$string =~ s/\]/\}/g;
	return $string;
}

'What exactly is zero?';

__END__

=head1 NAME

Number::Natural::SetTheory - set-theoretic definition of natural numbers

=head1 SYNOPSIS

 use Number::Natural::SetTheory qw/:all/;
 my $three = number_to_set(3);
 say (scalar @$three);   # says '3'
 
 # says '0', '1', and '2'
 foreach my $member (@$three)
 {
   say (scalar @$member);
 }
 
 # says '{{},{{}},{{},{{}}}}'
 say set_to_string($three);

=head1 DESCRIPTION

For years mathematicians struggled to answer what numbers exactly B<are>.
A satisfactory answer came out of the world of set theory. Because Perl
doesn't have sets as a first class data type, we use arrays instead. The
set theory notation for the set of the letters A, B and C is:

  { A, B, C }

The Perlish notation is:

  [ 'A', 'B', 'C' ]
  
For the rest of this documentation, we'll use Perlish notation unless
otherwise stated. Also, it's worth noting that sets are unordered, while
arrays are ordered. This module works around that difference by simply
ignoring the order of array elements.

Anyway, so what are numbers? We define zero as the empty set:

 our $zero = [];

Further natural numbers are defined as the set containing all smaller
natural numbers:

 our $one    = [$zero];
 our $two    = [$zero, $one];
 our $three  = [$zero, $one, $two];
 # etc

This has a nice property:

  scalar @$three == 3

Note that:

  our $not_three = [$zero, $zero, 'Chuck Norris'];
  scalar @$three == 3;   # true

In the case above, the set C<< $not_three >> does not represent a number
at all.

This module offers a number of functions for converting between Perl
non-negative integers and the sets representing the natural numbers.

=head2 set_is_number($set, $number)

Returns true (see L<boolean>) iff the set represents the number. Also
has the property that if C<$set> is an actual Perl scalar integer, it
returns true iff the two numbers are equal.

=head2 number_to_set($number)

Returns the set that represents a number, given a Perl scalar integer.
If C<< $number >> is not a number, then returns C<undef>.

=head2 set_to_number($set)

Converts a set to a Perl scalar integer. Returns C<undef> if the set does
not represent a number at all. This is the reverse of $number_to_set.

=head2 set_to_string($set)

Returns the set as a string, using number theory notation (curly brackets).

=head1 BUGS

These functions are very recursive. I wouldn't recommend using them with
numbers greater than ten.

This module doesn't really have any use cases.

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Number-Natural-SetTheory>.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Set-theoretic_definition_of_natural_numbers>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

