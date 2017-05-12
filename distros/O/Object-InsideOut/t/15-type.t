use strict;
use warnings;

use Test::More 'tests' => 34;

package My::Class; {
    use Object::InsideOut;

    sub is_scalar :Private { return (! ref(shift)); }

    sub is_int {
        my $arg = $_[0];
        return (Scalar::Util::looks_like_number($arg) &&
                (int($arg) == $arg));
    }

    my @aa :Field('acc'=>'aa', 'type' => 'array');
    my @as :Field('acc'=>'as', 'type' => 'array(My::Class)');
    my @ar :Field('acc'=>'ar', 'type' => 'array_ref');
    my @cc :Field({'acc'=>'cc', 'type' => sub{ shift > 0 } });
    my @hh :Field('acc'=>'hh', 'type' => 'hash');
    my @hr :Field('acc'=>'hr', 'type' => 'hashref');
    my @mc :Field({'acc'=>'mc', 'type' => 'My::Class'});
    my @nn :Field({'acc'=>'nn', 'type' => 'num'});
    my @sr :Field({'acc'=>'sr', 'type' => 'scalar_ref'});
    my @ss :Field
           :Acc(ss)
           :Type(\&My::Class::is_scalar);
    my @scal :Field :Acc(scal) :Type(scalar);

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
        'SC' => {
            'Field' => \@scal,
            'Type'  => 'scalar',
        }
    );
}

package main;

MAIN:
{
    my $obj = My::Class->new('DATA' => 5, 'SC' => 'bork');

    $obj->aa('test');
    is_deeply($obj->aa(), ['test']              => 'Array single value');
    $obj->aa('zero', 5);
    is_deeply($obj->aa(), ['zero', 5]           => 'Array multiple values');
    $obj->aa(['x', 42, 'z']);
    is_deeply($obj->aa(), ['x', 42, 'z']        => 'Array ref value');

    {
        my $a = My::Class->new();
        my $b = My::Class->new();
        my $c = My::Class->new();

        $obj->as($a);
        is_deeply($obj->as(), [$a]              => 'Array single class');
        $obj->as($a, $b, $c);
        is_deeply($obj->as(), [$a, $b, $c]      => 'Array multiple class');
        $obj->as([$c, $a, $b]);
        is_deeply($obj->as(), [$c, $a, $b]      => 'Array ref class');
    }

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

    $obj->ss('hello');
    is($obj->ss(), 'hello'                      => 'Scalar');
    eval { $obj->ss([1]); };
    like($@->message, qr/failed type check/     => 'Scalar failure');

    is($obj->scal(), 'bork'                     => 'Scalar');
    $obj->scal('foo');
    is($obj->scal(), 'foo'                      => 'Scalar');
    eval { $obj->scal(bless({}, 'Foo')); };
    like($@->message, qr/Bad argument/          => 'Scalar failure');

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

    eval { $obj2 = My::Class->new('SC' => []); };
    like($@->message, qr/Bad value/             => 'Scalar failure');

    eval { $obj2 = My::Class->new('BAD' => ''); };
    like($@->message, qr/Problem with type check routine/  => 'Type sub failure');

    $obj = bless({}, 'SomeClass');
    ok(UNIVERSAL::isa($obj, '') ||
       UNIVERSAL::isa($obj, 0) ||
       UNIVERSAL::isa($obj, 'SomeClass'), 'isa works');
}

exit(0);

# EOF
