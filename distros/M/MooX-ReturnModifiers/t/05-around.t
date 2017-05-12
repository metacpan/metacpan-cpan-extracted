use Test::More;

use MooX::ReturnModifiers qw/return_modifiers return_around/;

package Test::One::Thing;

use Moo;

package main;

my $caller = Test::One::Thing->new();

my %modifiers = &MooX::ReturnModifiers::return_modifiers($caller, ['around']);

ok(my $modifier = $modifiers{'around'}, "okay around key exists");
is(ref $modifier, 'CODE', "we have some code");
is(scalar keys %modifiers, 1, 'should only have one key');
ok(my $around = &MooX::ReturnModifiers::return_around($caller), 'return around');
is(ref $around, 'CODE', "we have some code");

done_testing();

1;



