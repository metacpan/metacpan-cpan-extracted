use strict;
use Test::More 0.98;
use Test::Exception;

subtest 'Simplest usage' => sub {
        {
            package Day;

            use strict;
            use warnings FATAL => 'all';
            use MouseX::Types::Enum qw/
                Sun
                Mon
                Tue
                Wed
                Thu
                Fri
                Sat
                /;

            __PACKAGE__->meta->make_immutable;
        }

        is(Day->Sun == Day->Sun, 1);
        is(Day->Sun == Day->Mon, '');
        is(Day->Sun->to_string, 'Sun');

        is_deeply(Day->enums, {
                Sun => Day->Sun,
                Mon => Day->Mon,
                Tue => Day->Tue,
                Wed => Day->Wed,
                Thu => Day->Thu,
                Fri => Day->Fri,
                Sat => Day->Sat
            });
    };

subtest 'Advanced usage' => sub {
        {
            package Fruits;

            use Mouse;
            use MouseX::Types::Enum (
                APPLE  => { name => 'Apple', color => 'red' },
                ORANGE => { name => 'Orange', color => 'orange' },
                BANANA => { name => 'Banana', color => 'yellow', has_seed => 0 }
            );

            has name => (is => 'ro', isa => 'Str');
            has color => (is => 'ro', isa => 'Str');
            has has_seed => (is => 'ro', isa => 'Int', default => 1);

            sub make_sentence {
                my ($self, $suffix) = @_;
                $suffix ||= "";
                return sprintf("%s is %s%s", $self->name, $self->color, $suffix);
            }

            __PACKAGE__->meta->make_immutable;
        }

        is(Fruits->APPLE == Fruits->APPLE, 1);
        is(Fruits->APPLE == Fruits->ORANGE, '');
        is(Fruits->APPLE->to_string, 'APPLE');

        # User-defined attributes and methods
        is(Fruits->APPLE->name, 'Apple');
        is(Fruits->APPLE->color, 'red');
        is(Fruits->APPLE->has_seed, 1);
        is(Fruits->APPLE->make_sentence('!!!'), 'Apple is red!!!');

        is_deeply(
            Fruits->enums,
            {
                APPLE  => Fruits->APPLE,
                ORANGE => Fruits->ORANGE,
                BANANA => Fruits->BANANA
            }
        );
    };


done_testing;
