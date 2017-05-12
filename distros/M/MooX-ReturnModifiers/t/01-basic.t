use Test::More;
{
   package Test::One::Thing;
   use Moo;
}

{ 
   package Dead::Die::Death;
   sub new { bless {}, $_[0]; }
}

package main;

use MooX::ReturnModifiers;

my $caller = Test::One::Thing->new();

my %moo_modifiers = &MooX::ReturnModifiers::return_modifiers($caller);

for (qw/has before after extends around with/) {
    ok(my $val = $moo_modifiers{$_}, "okay key exists");
    is(ref $val, 'CODE', "we have some code");
}

my %has_modifier = &MooX::ReturnModifiers::return_modifiers($caller, ['has']);

ok(my $has = $moo_modifiers{'has'}, "okay has key exists");
is(ref $has, 'CODE', "we have some code");
is(scalar keys %has_modifier, 1, 'should only have one key');

my $caller2 = Dead::Die::Death->new();

eval { &MooX::ReturnModifiers::return_modifiers($caller2, ['has']) };
like($@, qr/^Can\'t find method <has> in/);


done_testing();

1;




