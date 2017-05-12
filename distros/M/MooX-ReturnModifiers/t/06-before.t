use Test::More;

use MooX::ReturnModifiers qw/return_modifiers return_before/;

package Test::One::Thing;

use Moo;

package main;

my $caller = Test::One::Thing->new();

my %modifiers = &MooX::ReturnModifiers::return_modifiers($caller, ['before']);

ok(my $modifier = $modifiers{'before'}, "okay before key exists");
is(ref $modifier, 'CODE', "we have some code");
is(scalar keys %modifiers, 1, 'should only have one key');
ok(my $before = &MooX::ReturnModifiers::return_before($caller), 'return before');
is(ref $before, 'CODE', "we have some code");

done_testing();

1;



