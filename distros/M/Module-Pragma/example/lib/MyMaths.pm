package
	MyMaths;

use warnings;
use strict;

use myint ();

use overload '+' => sub {
	my ($l, $r) = @_;
	if (myint->enabled()) {
		int($$l) + int($$r);
	} else {
		$$l + $$r;
	}
};

sub new {
	my ($class, $value) = @_;
	bless \$value, $class;
}

1;
