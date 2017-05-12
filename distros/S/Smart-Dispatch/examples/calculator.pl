use feature qw( say );
use Smart::Dispatch;

{
	my @stack;
	my $eval = dispatcher {
		match qr{\d+}, dispatch { push @stack, $_ };
		match '+', dispatch { my ($x, $y) = splice(@stack, -2); push @stack, $x + $y };
		match '-', dispatch { my ($x, $y) = splice(@stack, -2); push @stack, $x - $y };
		match '*', dispatch { my ($x, $y) = splice(@stack, -2); push @stack, $x * $y };
		match '/', dispatch { my ($x, $y) = splice(@stack, -2); push @stack, $x / $y };
		match '%', dispatch { my ($x, $y) = splice(@stack, -2); push @stack, $x % $y };
		otherwise failover { warn "Unknown token '$_'\n" };
	};
	sub reverse_polish_calc {
		@stack = ();
		$eval->($_) for @_;
		wantarray ? @stack : $stack[-1];
	}
}


# ( 1 + ((2+3)*4) ) - 5 = 16
say reverse_polish_calc qw( 1 2 3 + 4 * + 5 - );

