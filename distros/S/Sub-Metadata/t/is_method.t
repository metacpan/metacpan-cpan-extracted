use warnings;
use strict;

use Test::More tests => 16;

BEGIN { use_ok "Sub::Metadata", qw(sub_is_method mutate_sub_is_method); }

sub t0;
sub t1 :method;
sub t2 { }
sub t3 :method { }

ok !sub_is_method(\&t0);
SKIP: {
	skip "pre-5.10 perl might not track methodness of undefined sub", 1
		unless "$]" >= 5.010;
	ok sub_is_method(\&t1);
}
ok !sub_is_method(\&t2);
ok sub_is_method(\&t3);
ok !sub_is_method(\&sub_is_method);

my @funcs = (\&t0, \&t1, \&t2, \&t3, \&sub_is_method);
mutate_sub_is_method($_, 0) foreach @funcs;
ok !sub_is_method($_) foreach @funcs;
mutate_sub_is_method($_, 1) foreach @funcs;
ok sub_is_method($_) foreach @funcs;

1;
