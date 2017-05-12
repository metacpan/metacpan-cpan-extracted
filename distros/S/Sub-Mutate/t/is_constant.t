use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Sub::Mutate", qw(sub_is_constant); }

ok !sub_is_constant(\&sub_is_constant);

sub t0;
sub t1 ();
sub t2 { 123 }
sub t3 () { 123 }
ok !sub_is_constant(\&t0);
ok !sub_is_constant(\&t1);
ok !sub_is_constant(\&t2);
ok sub_is_constant(\&t3);

sub mc($) { my $c = $_[0]; return sub () { $c } }

ok +(("$]" >= 5.019003 && "$]" < 5.020) xor sub_is_constant(mc(123)));

1;
