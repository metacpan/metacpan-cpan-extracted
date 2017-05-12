use warnings;
use strict;

use Sub::Mutate qw(
	sub_body_type sub_closure_role sub_is_lvalue sub_is_constant
	sub_is_method mutate_sub_is_method sub_is_debuggable
	mutate_sub_is_debuggable sub_prototype
);
use Test::More tests => 1 + 8*5;

BEGIN { use_ok "Sub::Filter", qw(mutate_sub_filter_return); }

our $t;
sub t0 { $t }
sub t1 ($) :method :lvalue { $t }
BEGIN {
	bless(\&t1, "BlessedCode");
	mutate_sub_is_debuggable(\&t1, 0);
}
sub t2 () { 123 }
BEGIN {
	bless(\&mutate_sub_is_debuggable, "BlessedCode");
	mutate_sub_is_debuggable(\&mutate_sub_is_debuggable, 0);
	mutate_sub_is_method(\&mutate_sub_is_debuggable, 1);
}

sub f0 { @_ }

my @slots = (
	sub { ref($_[0]) },
	\&sub_body_type,
	\&sub_closure_role,
	\&sub_is_lvalue,
	\&sub_is_method,
	\&sub_is_debuggable,
	\&sub_prototype,
);

foreach my $func (
	\&t0,
	\&t1,
	\&t2,
	\&Sub::Filter::_test_xs,
	\&mutate_sub_is_debuggable,
) {
	my @values = map { $_->($func) } @slots;
	mutate_sub_filter_return($func, \&f0);
	for(my $i = 0; $i != @slots; $i++) {
		is $slots[$i]->($func), $values[$i];
	}
	ok !sub_is_constant($func);
}

1;
