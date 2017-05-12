use Number::Fraction;

my $n = 12.48;
my $N = _decimalToRational($n);
print "$N\n";

sub _decimalToRational
{
	my ($d) = @_;
	
	my ($whole, $part) = split /\./, $d;
	
	my $numerator   = $whole.$part;
	my $denominator = '1'.('0' x length $part);
	
	return Number::Fraction->new($numerator, $denominator);
}