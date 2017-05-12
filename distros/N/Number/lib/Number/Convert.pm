package Number::Convert;

use strict;
use warnings;

use vars qw/$VERSION/;

$VERSION="1.0.2";

use overload (
	'+', 'add',
	'-', 'subtract',
	'*', 'multiply',
	'/', 'divide',
	'&', 'and',
	'|', 'or',
	'^', 'xor'
);

sub new
{
	my ($class, $param) = @_;	

	die "Invalid number of parameters passed to constructor. Expected was 1, found ".(scalar(@_) - 1).".\n" if(scalar(@_) != 2);

	die "Invalid value passed to parameter. $param is not a number" if(!isNumber($param));

	my $self = {
		number => $param
	};
	bless ($self, $class);
	return $self;
}

sub ToDecimal
{
	my $self = shift;
	return sprintf "%d", $self->{number};
}

sub ToBinary
{
	my $self = shift;
	return sprintf "%b", $self->{number};
}

sub ToHex
{
	my $self = shift;
	return sprintf "%x", $self->{number};
}

sub ToUpperCaseHex
{
	my $self = shift;
	return sprintf "%X", $self->{number};
}

sub ToOctal
{
	my $self = shift;
	return sprintf "%O", $self->{number};
}

sub add
{
	my $self = shift;
	my $value = shift;

	die "Can't add non numeric value to number\n" if(!defined($value) || !isNumber($value));

	$self->{number} += $value;
	return $self;
}

sub subtract
{
	my $self = shift;
	my $value = shift;

	die "Can't subtract non numeric value from number\n" if(!defined($value) || !isNumber($value));

	$self->{number} -= $value;
	return $self;
}

sub multiply
{
	my $self = shift;
	my $value = shift;

	die "Can't multiple number by non numeric value\n" if(!defined($value) || !isNumber($value));

	$self->{number} *= $value;
	return $self;
}

sub divide
{
	my $self = shift;
	my $value = shift;

	die "Can't divide number by non numeric value\n" if(!defined($value) || !isNumber($value));
	
	die "Division by zero not supported\n" if ($value == 0);
	
	$self->{number} /= $value;
	return $self;
}

sub and
{
	my $self = shift;
	my $value = shift;

	die "Can't AND number with non numeric value\n" if(!defined($value) || !isNumber($value));

	$self->{number} &= $value;
	return $self;
}

sub or
{
	my $self = shift;
	my $value = shift;

	die "Can't OR number with non numeric value\n" if(!defined($value) || !isNumber($value));

	$self->{number} |= $value;
	return $self;
}

sub xor
{
	my $self = shift;
	my $value = shift;

	die "Can't XOR number by non numeric value\n" if(!defined($value) || !isNumber($value));

	$self->{number} = $self->{number} ^ $value;
	return $self;
}

sub isNumber
{
	use POSIX qw(strtod);
	my $str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$! = 0;
	my($num, $unparsed) = strtod($str);
	if (($str eq '') || ($unparsed != 0) || $!) {
		return 0;
	}
	else {
		return 1;
	}
}

1;

__END__

=head1 NAME

Number::Convert - Perl extension to convert numbers between different base systems.

=head1 SYNOPSIS

	use Number::Convert;

	my $a = new Number::Convert(0xff);

	$a += "abcdef";
	$a ^= 0b000011111;

	print $a->ToBinary()."\n";

	print Number::Convert->new(0xff)->ToDecimal()."\n";

=head1 DESCRIPTION

This extension provides for easy conversion of numbers between different bases.
It currently supports base 2, 8, 10 & 16 (binary, octal, decimal & hex). It also
supports basic perl operations on numbers such as add, subtract, multiply, divide
and a few bitwise operators such as and, or, xor.

=head2 Overloaded operators.

The following binary operators have been overloaded so that you can perform operations
on Number::Convert objects as if they were normal scalars.

+, -, *, /, &, |, ^ (xor)

=head2 Other functions

=item ToDecimal

Will return the number in decimal format

=item ToBinary

Will return the number in binary format

=item ToHex

Will return the number in hexadecimal format

=item ToUpperCaseHex

Will return the number in hexadecimal format, but using uppercase for letters A-Z.

=item ToOctal

Will return the number in octal format.

=head1 SEE ALSO

If you have any questions/issues, please feel free to reach out to the author.

=head1 AUTHOR

Karthik Umashankar <karthiku@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Karthik Umashankar

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
