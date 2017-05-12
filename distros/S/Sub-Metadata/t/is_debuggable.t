use warnings;
use strict;

use Test::More tests => 16;

BEGIN {
	use_ok "Sub::Metadata", qw(sub_is_debuggable mutate_sub_is_debuggable);
}

sub t0;
sub t1 { }
{
	package DB;
	sub t2;
	sub t3 { }
}

my @funcs = (\&t0, \&t1, \&DB::t2, \&DB::t3, \&sub_is_debuggable);
ok sub_is_debuggable($_) foreach @funcs;
mutate_sub_is_debuggable($_, 0) foreach @funcs;
ok !sub_is_debuggable($_) foreach @funcs;
mutate_sub_is_debuggable($_, 1) foreach @funcs;
ok sub_is_debuggable($_) foreach @funcs;

1;
