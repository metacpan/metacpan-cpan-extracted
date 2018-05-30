use strict;
use Test::More 0.98;
use Scalar::Util qw/refaddr/;
use Test::Exception;

BEGIN {
    use File::Basename qw/dirname/;
    my $dir = dirname(__FILE__);
    push(@INC, $dir);
}

use Fruits;
use Day;

subtest 'Correct enum objects are generated' => sub {
        ok(Fruits->APPLE);
        ok(Fruits->ORANGE);
        ok(Fruits->BANANA);

        ok(Day->Sun);
        ok(Day->Mon);
        ok(Day->Tue);
        ok(Day->Wed);
        ok(Day->Thu);
        ok(Day->Fri);
        ok(Day->Sat);
    };

subtest 'Each objects are singleton' => sub {
        ok(refaddr(Fruits->APPLE) eq refaddr(Fruits->APPLE));
        ok(refaddr(Fruits->ORANGE) eq refaddr(Fruits->ORANGE));
        ok(refaddr(Fruits->BANANA) eq refaddr(Fruits->BANANA));

        ok(refaddr(Day->Sun) eq refaddr(Day->Sun));
        ok(refaddr(Day->Mon) eq refaddr(Day->Mon));
        ok(refaddr(Day->Tue) eq refaddr(Day->Tue));
        ok(refaddr(Day->Wed) eq refaddr(Day->Wed));
        ok(refaddr(Day->Thu) eq refaddr(Day->Thu));
        ok(refaddr(Day->Fri) eq refaddr(Day->Fri));
        ok(refaddr(Day->Sat) eq refaddr(Day->Sat));
    };

subtest 'Operator `==` works correctly' => sub {
        ok(Fruits->APPLE == Fruits->APPLE);
        ok(Fruits->ORANGE == Fruits->ORANGE);
        ok(Fruits->BANANA == Fruits->BANANA);

        ok(!(Fruits->APPLE == Fruits->ORANGE));
        ok(!(Fruits->ORANGE == Fruits->APPLE));
        ok(!(Fruits->APPLE == Fruits->BANANA));
        ok(!(Fruits->BANANA == Fruits->APPLE));
        ok(!(Fruits->ORANGE == Fruits->BANANA));
        ok(!(Fruits->BANANA == Fruits->ORANGE));

        ok(!(Fruits->APPLE == 123));
        ok(!(123 == Fruits->APPLE));
        ok(!(Fruits->APPLE == 'foo'));
        ok(!('foo' == Fruits->APPLE));
    };

subtest 'Operator `!=` works correctly' => sub {
        ok(!(Fruits->APPLE != Fruits->APPLE));
        ok(!(Fruits->ORANGE != Fruits->ORANGE));
        ok(!(Fruits->BANANA != Fruits->BANANA));

        ok(Fruits->APPLE != Fruits->ORANGE);
        ok(Fruits->ORANGE != Fruits->APPLE);
        ok(Fruits->APPLE != Fruits->BANANA);
        ok(Fruits->BANANA != Fruits->APPLE);
        ok(Fruits->ORANGE != Fruits->BANANA);
        ok(Fruits->BANANA != Fruits->ORANGE);

        ok(Fruits->APPLE != 1);
        ok(1 != Fruits->APPLE);
        ok(Fruits->APPLE != 123);
        ok(123 != Fruits->APPLE);
        ok(Fruits->APPLE != 'foo');
        ok('foo' != Fruits->APPLE);
    };

subtest 'Operator `eq` works correctly' => sub {
        ok(Fruits->APPLE eq Fruits->APPLE);
        ok(Fruits->ORANGE eq Fruits->ORANGE);
        ok(Fruits->BANANA eq Fruits->BANANA);

        ok(!(Fruits->APPLE eq Fruits->ORANGE));
        ok(!(Fruits->ORANGE eq Fruits->APPLE));
        ok(!(Fruits->APPLE eq Fruits->BANANA));
        ok(!(Fruits->BANANA eq Fruits->APPLE));
        ok(!(Fruits->ORANGE eq Fruits->BANANA));
        ok(!(Fruits->BANANA eq Fruits->ORANGE));

        ok(!(Fruits->APPLE eq 1));
        ok(!(1 eq Fruits->APPLE));
        ok(!(Fruits->APPLE eq 123));
        ok(!(123 eq Fruits->APPLE));
        ok(!(Fruits->APPLE eq 'foo'));
        ok(!('foo' eq Fruits->APPLE));
    };

subtest 'Operator `ne` works correctly' => sub {
        ok(!(Fruits->APPLE ne Fruits->APPLE));
        ok(!(Fruits->ORANGE ne Fruits->ORANGE));
        ok(!(Fruits->BANANA ne Fruits->BANANA));

        ok(Fruits->APPLE ne Fruits->ORANGE);
        ok(Fruits->ORANGE ne Fruits->APPLE);
        ok(Fruits->APPLE ne Fruits->BANANA);
        ok(Fruits->BANANA ne Fruits->APPLE);
        ok(Fruits->ORANGE ne Fruits->BANANA);
        ok(Fruits->BANANA ne Fruits->ORANGE);

        ok(Fruits->APPLE ne 1);
        ok(1 ne Fruits->APPLE);
        ok(Fruits->APPLE ne 123);
        ok(123 ne Fruits->APPLE);
        ok(Fruits->APPLE ne 'foo');
        ok('foo' ne Fruits->APPLE);
    };

subtest 'Cannot use other binary operators' => sub {
        throws_ok {Fruits->APPLE > Fruits->ORANGE;} qr//;
        throws_ok {Fruits->APPLE >= Fruits->ORANGE;} qr//;
        throws_ok {Fruits->APPLE < Fruits->ORANGE;} qr//;
        throws_ok {Fruits->APPLE <= Fruits->ORANGE;} qr//;
        throws_ok {Fruits->APPLE + Fruits->ORANGE;} qr//;
        throws_ok {Fruits->APPLE + Fruits->ORANGE;} qr//;
    };

subtest 'Converted to string correctly' => sub {
        is("" . Fruits->APPLE, "APPLE");
        is(Fruits->APPLE . "", "APPLE");
        is("" . Day->Sun, "Sun");
        is(Day->Sun . "", "Sun");

        is(Fruits->BANANA->to_string, "BANANA");
        is(Day->Mon->to_string, "Mon");
    };

subtest 'Call instance method' => sub {
        is(Fruits->APPLE->make_sentence, "Apple is red");
        is(Fruits->ORANGE->make_sentence, "Orange is orange");
        is(Fruits->BANANA->make_sentence('!!!'), "Banana is yellow!!!");
    };

subtest 'Correct values is set' => sub {
        is(Fruits->APPLE->name, 'Apple');
        is(Fruits->ORANGE->name, 'Orange');
        is(Fruits->BANANA->name, 'Banana');
        is(Fruits->APPLE->color, 'red');
        is(Fruits->ORANGE->color, 'orange');
        is(Fruits->BANANA->color, 'yellow');
        is(Fruits->APPLE->has_seed, 1);
        is(Fruits->ORANGE->has_seed, 1);
        is(Fruits->BANANA->has_seed, 0);
    };

subtest 'Lazy loading' => sub {
        {
            package Foo;
            use MouseX::Types::Enum (
                'A',
                'B',
                'C'
            );
        }

        is((scalar grep {$_} values %{ Foo->_instances }), 0);
        is(Foo->_instances->{A}, undef);
        Foo->A;
        is((scalar grep {$_} values %{ Foo->_instances }), 1);
        is(Foo->_instances->{A}, Foo->A);

        my $enums = Foo->enums;
        is_deeply($enums, {
                A => Foo->A,
                B => Foo->B,
                C => Foo->C,
            });
    };

subtest 'Get all enums' => sub {
        is_deeply(
            Fruits->enums,
            {
                APPLE  => Fruits->APPLE,
                ORANGE => Fruits->ORANGE,
                BANANA => Fruits->BANANA
            }
        );
        is_deeply(
            Day->enums,
            {
                Sun => Day->Sun,
                Mon => Day->Mon,
                Tue => Day->Tue,
                Wed => Day->Wed,
                Thu => Day->Thu,
                Fri => Day->Fri,
                Sat => Day->Sat
            }
        );
    };

subtest 'Subroutine scopes' => sub {
        subtest 'Has private constructor' => sub {
                throws_ok {
                        Fruits->new({
                            GRAPE => { name => 'Grape', color => 'Purple' }
                        })
                    } qr/Can't instantiate/;
            };

        subtest 'Each enum objects cannot call itself' => sub {
                throws_ok {
                        Fruits->APPLE->APPLE
                    } qr/`APPLE` can only be called/;
            };

        subtest "Can't invoke class method from instances" => sub {
                throws_ok {
                        Fruits->APPLE->enums
                    } qr/is class method/;
            };
    };

subtest 'Reserved words' => sub {
        subtest 'Attribute name `_id` is reserved' => sub {
                throws_ok {
                        {
                            package Hoge;

                            # Pseudo use package
                            require MouseX::Types::Enum;
                            MouseX::Types::Enum->import(
                                Foo => { _id => 'foo' }
                            );
                        }
                    } qr/`Hoge::_id` is reserved./;
            };

        subtest 'Cannot declare reserved word as key' => sub {
                for (qw/_equals _not_equals enums to_string _instances/) {
                    throws_ok {
                            {
                                package Buzz;

                                # Pseudo use package
                                require MouseX::Types::Enum;
                                MouseX::Types::Enum->import(
                                    $_ => {},
                                );
                            }
                        } qr/`Buzz::$_` is already defined or reserved/, '';

                }
            };
    };

done_testing;
