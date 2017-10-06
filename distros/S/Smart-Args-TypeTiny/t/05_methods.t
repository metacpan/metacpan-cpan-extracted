use Test2::V0;

{
    package Foo;
    use Moo;
    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub class_method {
        args my $class,
             my $ppp => Str;
        return "CLASS_METHOD: $class, $ppp";
    }

    sub instance_method {
        args my $self,
             my $ppp => Str;
        return sprintf("INSTANCE_METHOD: %s, $ppp", ref($self));
    }

    sub must_be_instance_method {
        args my $self => Object, my $ppp;
        return sprintf 'MUST_BE_INSTANCE_METHOD: %s, %s', ref $self, $ppp;
    }
}

{
    package Bar;
    use Moo;
    use Smart::Args::TypeTiny;
    use Types::Standard -all;

    sub class_method {
        args_pos my $class,
                 my $ppp => Str;
        return "CLASS_METHOD: $class, $ppp";
    }

    sub instance_method {
        args_pos my $self,
                 my $ppp => Str;
        return sprintf("INSTANCE_METHOD: %s, $ppp", ref($self));
    }

    sub must_be_instance_method {
        args_pos my $self => Object, my $ppp;
        return sprintf 'MUST_BE_INSTANCE_METHOD: %s, %s', ref $self, $ppp;
    }
}

is(Foo->class_method(ppp => "YAY"), "CLASS_METHOD: Foo, YAY");
is(Foo->new->instance_method(ppp => "PEY"), "INSTANCE_METHOD: Foo, PEY");

is(Foo->new->must_be_instance_method(ppp => 'WOW'),
    'MUST_BE_INSTANCE_METHOD: Foo, WOW');

like dies {
    Foo->must_be_instance_method(ppp => 42);
}, qr/Type check failed in binding to parameter '\$self'; Value "Foo" did not pass type constraint "Object"/;

is(Bar->class_method("YAY"), "CLASS_METHOD: Bar, YAY");
is(Bar->new->instance_method("PEY"), "INSTANCE_METHOD: Bar, PEY");

is(Bar->new->must_be_instance_method('WOW'),
    'MUST_BE_INSTANCE_METHOD: Bar, WOW');

like dies {
    Bar->must_be_instance_method(42);
}, qr/Type check failed in binding to parameter '\$self'; Value "Bar" did not pass type constraint "Object"/;

done_testing;
