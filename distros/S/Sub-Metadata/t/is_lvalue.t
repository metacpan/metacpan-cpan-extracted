use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Sub::Metadata", qw(sub_is_lvalue); }

sub t0;
sub t1 :lvalue;
our $x;
sub t2 { $x }
sub t3 :lvalue { $x }

ok !sub_is_lvalue(\&t0);
SKIP: {
	skip "pre-5.10 perl might not track lvalueness of undefined sub", 1
		unless "$]" >= 5.010;
	ok sub_is_lvalue(\&t1);
}
ok !sub_is_lvalue(\&t2);
ok sub_is_lvalue(\&t3);
ok !sub_is_lvalue(\&sub_is_lvalue);

1;
