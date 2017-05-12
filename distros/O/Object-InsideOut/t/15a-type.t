use strict;
use warnings;

use Test::More 'tests' => 32;

package My::Class; {
    use Object::InsideOut;

    sub is_scalar :Private { return (! ref(shift)); }

    sub is_int {
        my $arg = $_[0];
        return (Scalar::Util::looks_like_number($arg) &&
                (int($arg) == $arg));
    }

    my @aa :Field
           :Acc(aa) :Name(aa)
           :Type(array);
    my @ar :Field
           :Acc(ar)
           :Type(array_ref);
    my @cc :Field
           :Acc(cc)
           :Type(sub{ shift > 0 });
    my @hh :Field
           :Acc(hh)
           :Type(hash);
    my @hr :Field
           :Acc(hr) :Name(hr)
           :Type(hashref);
    my @mc :Field
           :Acc(mc)
           :Type(My::Class);
    my @nn :Field
           :Acc(nn)
           :Type(num);
    my @ns :Field
           :Acc(ns)
           :Type(list(num));
    my @ss :Field
           :Acc(ss)
           :Type(\&My::Class::is_scalar);
    my @sr :Field
           :Acc(sr)
           :Type(SCALARref);

    my %init_args :InitArgs = (
        'DATA' => {
            'Field' => \@nn,
            'Type'  => \&is_int,
        },
        'INFO' => {
            'Type'  => sub { $_[0] }
        },
        'BAD' => {
            'Type'  => sub { shift > 0 }
        },
    );
}

package Foo; {
    use Object::InsideOut;

    my @foo :Field :Acc(foo);
    my @array_of_num  :Field :All(array_of_num) :Type( ARRAY_ref(numeric) );

    my %init_args :InitArgs = (
        'FOO' => {
            'field' => \@foo,
            'type' => 'ARRAYref(UNIVERSAL)'
        },
    );
}

package main;

MAIN:
{
    my $obj = My::Class->new('DATA' => 5);

    $obj->aa('test');
    is_deeply($obj->aa(), ['test']              => 'Array single value');
    $obj->aa('zero', 5);
    is_deeply($obj->aa(), ['zero', 5]           => 'Array multiple values');
    $obj->aa(['x', 42, 'z']);
    is_deeply($obj->aa(), ['x', 42, 'z']        => 'Array ref value');

    eval { $obj->ar('test'); };
    like($@->message, qr/Wrong type/            => 'Not array ref');
    $obj->ar([3, [ 'a' ]]);
    is_deeply($obj->ar(), [3, [ 'a' ]]          => 'Array ref');

    $obj->cc(12);
    is($obj->cc(), 12                           => 'Type sub');
    eval { $obj->cc(-5); };
    like($@->message, qr/failed type check/     => 'Type failure');
    eval { $obj->cc('hello'); };
    like($@->message, qr/Problem with type check routine/  => 'Type sub failure');

    $obj->hh('x' => 5);
    is_deeply($obj->hh(), {'x'=>5}              => 'Hash single pair');
    $obj->hh('a' => 'z', '0' => '9');
    is_deeply($obj->hh(), {'a'=>'z','0'=>'9'}   => 'Hash multiple pairs');
    $obj->hh({'2b'=>'not'});
    is_deeply($obj->hh(), {'2b'=>'not'}         => 'Hash ref value');

    eval { $obj->hr('test'); };
    like($@->message, qr/Wrong type/            => 'Not hash ref');
    $obj->hr({'frog'=>{'prince'=>'John'}});
    is_deeply($obj->hr(), {'frog'=>{'prince'=>'John'}} => 'Hash ref');

    my $obj2 = My::Class->new();
    $obj->mc($obj2);
    my $obj3 = $obj->mc();
    isa_ok($obj3, 'My::Class'                   => 'Object');
    is($$obj3, $$obj2                           => 'Objects equal');
    eval { $obj2->mc('test'); };
    like($@->message, qr/Wrong type/            => 'Not object');

    $obj->nn(99);
    is_deeply($obj->nn(), 99                    => 'Numeric');
    eval { $obj->nn('x'); };
    like($@->message, qr/Bad argument/          => 'Numeric failure');

    $obj->ns(86);
    is_deeply($obj->ns(), [86]                  => 'Array single num');
    $obj->ns(1, 2.5, 5);
    is_deeply($obj->ns(), [1, 2.5, 5]           => 'Array multiple num');
    $obj->ns([42, 0, -1]);
    is_deeply($obj->ns(), [42, 0, -1]           => 'Array ref num');

    $obj->ss('hello');
    is($obj->ss(), 'hello'                      => 'Scalar');
    eval { $obj->ss([1]); };
    like($@->message, qr/failed type check/     => 'Scalar failure');

    eval { $obj->sr('test'); };
    like($@->message, qr/Wrong type/            => 'Not scalar ref');
    my $x = 42;
    $obj->sr(\$x);
    is($obj->sr(), \$x                          => 'Scalar ref');
    my $y = $obj->sr();
    is($$y, 42                                  => 'Scalar ref value');

    eval { $obj2 = My::Class->new('DATA' => 'hello'); };
    like($@->message, qr/failed type check/     => 'Type failure');

    eval { $obj2 = My::Class->new('INFO' => ''); };
    like($@->message, qr/failed type check/     => 'Type failure');

    eval { $obj2 = My::Class->new('BAD' => ''); };
    like($@->message, qr/Problem with type check routine/  => 'Type sub failure');

    my $foo = Foo->new();
    my $foo2 = Foo->new('FOO' => [ $foo, $obj ]);
    is_deeply($foo2->foo(), [ $foo, $obj ]      => 'InitArgs type arrayref(UNIV)');
    my $foo3 = Foo->new('array_of_num' => [ 1957, 42, 3.14 ]);
    is_deeply($foo3->array_of_num(), [ 1957, 42, 3.14 ]  => 'InitArgs type arrayref(numeric)');
    $foo3->array_of_num( [1,2,3] );
    is_deeply($foo3->array_of_num(), [ 1, 2, 3 ]  => 'Set arrayref(numeric)');
}

exit(0);

# EOF
