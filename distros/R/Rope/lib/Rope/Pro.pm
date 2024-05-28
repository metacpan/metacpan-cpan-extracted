package Rope::Pro;

my (%PRO);

BEGIN {
	%PRO = (
		keyword => sub {
			my ($caller, $method, $cb) = @_;
			no strict 'refs';
			*{"${caller}::${method}"} = $cb;
		}
	);
}

sub new {
	shift;
	return (
		%PRO,
		@_
	);
}

1;

__END__
