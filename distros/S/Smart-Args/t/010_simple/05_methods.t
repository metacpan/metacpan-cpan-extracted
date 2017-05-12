use strict;
use warnings;
use Smart::Args;
use Test::More;
use t::Util;

{
    package Foo;
    use Mouse;
    use Smart::Args;
    sub class_method {
	args my $class,
	     my $ppp => 'Str';
	return "CLASS_METHOD: $class, $ppp";
    }
    sub instance_method {
	args my $self,
	     my $ppp => 'Str';
	return sprintf("INSTANCE_METHOD: %s, $ppp", ref($self));
    }


    sub must_be_instance_method {
        args my $self => 'Object', my $ppp;
        return sprintf 'MUST_BE_INSTANCE_METHOD: %s, %s', ref $self, $ppp;
    }
}

is( Foo->class_method(ppp => "YAY"), "CLASS_METHOD: Foo, YAY");
is(Foo->new->instance_method(ppp => "PEY"), "INSTANCE_METHOD: Foo, PEY");

is( Foo->new->must_be_instance_method(ppp => 'WOW'),
    'MUST_BE_INSTANCE_METHOD: Foo, WOW');

throws_ok {
    Foo->must_be_instance_method(ppp => 42);
} qr/Validation failed for 'Object' with value Foo/;

done_testing;
