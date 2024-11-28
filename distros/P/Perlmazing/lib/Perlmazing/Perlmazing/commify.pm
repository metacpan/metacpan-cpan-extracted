use Perlmazing qw(is_number);
use CLDR::Number;
my $cldr = CLDR::Number->new(locale => 'en');
my $decf = $cldr->decimal_formatter;
our @ISA = qw(Perlmazing::Listable);

sub main {
	return unless $_[0];
	my $n = $_[0];
	my $point = $decf->{decimal_sign};
	my $comma = $decf->{group_sign};
	my $plus = $decf->{plus_sign};
	my $minus = $decf->{minus_sign};
	my $sign = substr($n, 0, 1);
	my $decimals;
	if ($sign =~ /^([$plus]|[$minus])/) {
		$n = substr $n, 1;
	} else {
		undef $sign;
	}
	$n =~ s/[^\d$point$comma]+//g;
	return unless $n;
	if ($n =~ /[$point](\d+)$/) {
		$decimals = $1;
		$n =~ s/[$point]\d+$//;
		return if $n =~ /[$point]/;
	}
	$n = 0 unless $n;
	$n = "$sign$n" if $sign;
	$n =~ s/$comma//g;
	return unless $n;
	$n = $decf->format($n);
	$n .= "${point}${decimals}" if $decimals;
	$_[0] = $n;
}

1;
