use Test::Most;

use_ok('PerlMongers::MadMongers');

my $mm = PerlMongers::MadMongers->new;

isa_ok($mm, 'PerlMongers::MadMongers');

is(ref $mm->members, 'ARRAY', 'is our members list really an array ref');

cmp_ok(@{$mm->members}, '>', 0, 'do we have any members');

ok($mm->website);

cmp_ok($mm->add_values(3,4), '==', 7, 'can we add?');

done_testing();


