use strict;
use warnings;

use Test::More 'tests' => 20;

package MyBase; {
    use Object::InsideOut;

    sub everyone             { return 'everyone'; }
    sub family   :RESTRICTED { return 'family';   }
    sub personal :PRIVATE    { return 'personal'; }

    sub try_all {
        my $self = $_[0];
        for my $method (qw(everyone family personal)) {
            Test::More::is($self->$method(), $method => "Called $method");
        }
    }
}

package MyDer; {
    use Object::InsideOut qw(MyBase);

    sub everyone             { my $self = shift; $self->SUPER::everyone(); }
    sub family   :RESTRICTED { my $self = shift; $self->SUPER::family();   }
    sub personal :PRIVATE    { my $self = shift; $self->SUPER::personal(); }
}


package Foo; {
    use Object::InsideOut;

    sub foo_priv :Private(Baz)
    {
        my $self = shift;
        return ('okay');
    }

    sub foo_restr :Restricted(Baz)
    {
        my $self = shift;
        return ('okay');
    }
}

package Bar; {
    use Object::InsideOut 'Foo';

    sub bar
    {
        my $self = shift;
        return ($self->foo_restr);
    }
}

package Baz; {
    use Object::InsideOut;

    sub baz
    {
        my ($self, $bar, $foo) = @_;

        Test::More::is($bar->bar,       'okay', ':Restricted');
        Test::More::is($foo->foo_restr, 'okay', ':Restricted exception');
        Test::More::is($foo->foo_priv,  'okay', ':Private exception');
    }
}


package main;

MAIN:
{
    my $base_obj = MyBase->new();
    my $der_obj  = MyDer->new();

    $base_obj->try_all();

    ok(!eval { $der_obj->try_all(); 1 }   => 'Derived call failed');
    is($@->error(), q/Can't call private method 'MyDer->personal' from class 'MyBase'/
                                          => '...with correct error message');

    is($base_obj->everyone, 'everyone' => 'External everyone succeeded');
    ok(!eval { $base_obj->family }     => 'External family failed as expected');
    is($@->error(), q/Can't call restricted method 'MyBase->family' from class 'main'/
                                          => '...with correct error message');

    ok(!eval { $base_obj->personal }   => 'External personal failed as expected');
    is($@->error(), q/Can't call private method 'MyBase->personal' from class 'main'/
                                          => '...with correct error message');

    is($der_obj->everyone, 'everyone' => 'External derived everyone succeeded');
    ok(!eval { $der_obj->family }     => 'External derived family failed as expected');
    is($@->error(), q/Can't call restricted method 'MyDer->family' from class 'main'/
                                          => '...with correct error message');

    ok(!eval { $der_obj->personal }   => 'External derived personal failed as expected');
    is($@->error(), q/Can't call private method 'MyDer->personal' from class 'main'/
                                          => '...with correct error message');

    Baz->new()->baz(Bar->new(), Foo->new());
}

exit(0);

# EOF
