use warnings;
use strict;

use Test::More tests => 1 + 3*4*2;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

{
	package live;
	sub new { bless [0, $_[1]], $_[0] }
	sub done { $_[0]->[0]++ }
	sub DESTROY { ::ok $_[0]->[0], "$_[0]->[1]: survived until done" }
}

my %test = (
	assigned_lexical => sub {
		isa_ok($_[1], "live", "assigned_lexical: initial");
		my $return = shift;
		my($lexical) = @_;
		$return->($lexical);
	},
	shifted_lexical => sub {
		isa_ok($_[1], "live", "shifted_lexical: initial");
		my $return = shift;
		my $lexical = shift;
		$return->($lexical);
	},
	array => sub {
		isa_ok($_[1], "live", "array: initial");
		my $return = shift;
		$return->(@_);
	},
	shift => sub {
		isa_ok($_[1], "live", "shift: initial");
		my $return = shift;
		$return->(shift);
	},
);

foreach my $name (sort keys %test) {
	my $ret = do {
		$test{$name}->(current_escape_function, live->new("$name s"))
	};
	isa_ok($ret, "live", "$name s: returned") && $ret->done;
}

foreach my $name (sort keys %test) {
	my @ret = do {
		$test{$name}->(current_escape_function, live->new("$name a"))
	};
	isa_ok($ret[0], "live", "$name a: returned") && $ret[0]->done;
}

1;
