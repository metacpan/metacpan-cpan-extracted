use Test::More;

use MooX::ReturnModifiers qw/return_modifiers return_has/;

package Test::One::Thing;

use Moo;

package main;

my $caller = Test::One::Thing->new();

my %modifiers = &MooX::ReturnModifiers::return_modifiers($caller, ['has']);

ok(my $modifier = $modifiers{'has'}, "okay has key exists");
is(ref $modifier, 'CODE', "we have some code");
is(scalar keys %modifiers, 1, 'should only have one key');
ok(my $has = &MooX::ReturnModifiers::return_has($caller), 'return has');
is(ref $has, 'CODE', "we have some code");

done_testing();

1;



