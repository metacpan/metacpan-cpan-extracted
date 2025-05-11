package Rope::Pro;

use strict; use warnings;
my (%PRO);

BEGIN {
	%PRO = (
		keyword => sub {
			my ($caller, $method, $cb) = @_;
			no strict 'refs';
			no warnings 'redefine';
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
