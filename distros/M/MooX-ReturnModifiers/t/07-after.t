use Test::More;

use MooX::ReturnModifiers qw/return_modifiers return_after/;

package Test::One::Thing;

use Moo;

package main;

my $caller = Test::One::Thing->new();

my %modifiers = &MooX::ReturnModifiers::return_modifiers($caller, ['after']);

ok(my $modifier = $modifiers{'after'}, "okay after key exists");
is(ref $modifier, 'CODE', "we have some code");
is(scalar keys %modifiers, 1, 'should only have one key');
ok(my $after = &MooX::ReturnModifiers::return_after($caller), 'return after');
is(ref $after, 'CODE', "we have some code");

done_testing();

1;



