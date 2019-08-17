use Test::More;
use lib 't/lib';

use RoleHasAttributes;
my $extends = RoleHasAttributes->new;

is($extends->one, 20, 'okay we got 20');
is_deeply($extends->two, [qw/four five six/], 'is deeply');
is_deeply($extends->three, { three => 'four' }, 'is deeply');
is($extends->four, 'a different value', 'a default value');
isa_ok($extends->five, 'Okays');
is($extends->six, 1, "a true value");
is($extends->seven, undef, "undef value");
is($extends->eight, undef, "undef value");
is_deeply($extends->eleven, 'ahhhhhhhhhhhhh', 'arrayref of names - eleven');
is_deeply($extends->twelve, 'ahhhhhhhhhhhhh', 'arrayref of names - twelve');
is_deeply($extends->thirteen, 'ahhhhhhhhhhhhh', 'arrayref of names - thirteen');
is($extends->fourteen, 40000, 'okay 100');

done_testing();
