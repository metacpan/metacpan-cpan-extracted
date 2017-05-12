use Test::More;

use MooX::ReturnModifiers qw/return_modifiers return_extends/;

package Test::One::Thing;

use Moo;

package main;

my $caller = Test::One::Thing->new();

my %modifiers = &MooX::ReturnModifiers::return_modifiers($caller, ['extends']);

ok(my $modifier = $modifiers{'extends'}, "okay extends key exists");
is(ref $modifier, 'CODE', "we have some code");
is(scalar keys %modifiers, 1, 'should only have one key');
ok(my $extends = &MooX::ReturnModifiers::return_extends($caller), 'return extends');
is(ref $extends, 'CODE', "we have some code");

done_testing();

1;



