use Test::More;

use MooX::ReturnModifiers qw/return_modifiers return_with/;

package Test::One::Thing;

use Moo;

package main;

my $caller = Test::One::Thing->new();

my %modifiers = &MooX::ReturnModifiers::return_modifiers($caller, ['with']);

ok(my $modifier = $modifiers{'with'}, "okay with key exists");
is(ref $modifier, 'CODE', "we have some code");
is(scalar keys %modifiers, 1, 'should only have one key');
ok(my $with = &MooX::ReturnModifiers::return_with($caller), 'return with');
is(ref $with, 'CODE', "we have some code");

done_testing();

1;



