use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok "Sub::Filter", qw(mutate_sub_filter_return); }

sub f1;
sub f2 { "foo" }
sub t1;
sub t2 { "foo" }

eval { mutate_sub_filter_return(\&t0, \&f2) };
like $@, qr/\Acan't apply return filter to undefined subroutine/;
eval { mutate_sub_filter_return(\&t1, \&f2) };
like $@, qr/\Acan't apply return filter to undefined subroutine/;

eval { mutate_sub_filter_return(\&t2, \&f1) };
is $@, "";
eval { t2() };
like $@, qr/\AUndefined subroutine/;

1;
