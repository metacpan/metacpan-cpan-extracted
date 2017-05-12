use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental::Char;

sub new {
    my $ch = String::Incremental::Char->new( @_ );
    return $ch;
}

subtest 'args' => sub {
    dies_ok {
        new();
    } 'nothing';

    subtest 'order' => sub {
        lives_ok {
            new( order => 'abc' );
        } 'Str';

        lives_ok {
            new( order => ['a'..'c'] );
        } 'ArrayRef';

        dies_ok {
            new( order => 'abca' );
        } 'Str: duplicated character(s)';

        dies_ok {
            new ( order => ['a'..'c', 'b'] );
        } 'ArrayRef: duplicated element(s)';
    };

    subtest 'upper' => sub {
        dies_ok {
            new( order => 'a', upper => undef );
        } 'invalid: inplicit Undef';

        dies_ok {
            new( order => 'a', upper => 'foobar' );
        } 'invalid: Str';

        lives_ok {
            my $upper = new( order => 'abc' );
            new( order => 'a', upper => $upper );
        };
    };

    subtest 'set' => sub {
        dies_ok {
            new( order => 'abc', set => 'ab' );
        } 'invalid: not is-a Char';

        dies_ok {
            new( order => 'abc', set => 'd' );
        } 'invalid: not in order';

        lives_ok {
            new( order => 'abc', set => 'c' );
        };
    }
};

subtest 'properties' => sub {
    subtest 'from Str' => sub {
        subtest 'basic' => sub {
            my $ch = new( order => 'abcde' );
            is_deeply $ch->order, ['a', 'b', 'c', 'd', 'e'];
            is $ch->__size, 5;
            is $ch->__i, 0;
        };

        subtest 'internal use' => sub {
            lives_ok {
                my $ch = new( order => 'abcde', __i => 2 );
                is_deeply $ch->order, ['a', 'b', 'c', 'd', 'e'];
                is $ch->__size, 5;
                is $ch->__i, 2;
            } 'valid';

            dies_ok {
                my $ch = new( order => 'abcde', __i => 5 );
            } '__i: should be less than size of "order"';
        };
    };

    subtest 'from ArrayRef' => sub {
        subtest 'basic' => sub {
            my $ch = new( order => ['a', 'b', 'c', 'd', 'e'] );
            is_deeply $ch->order, ['a', 'b', 'c', 'd', 'e'];
            is $ch->__size, 5;
            is $ch->__i, 0;
        };

        subtest 'internal use' => sub {
            lives_ok {
                my $ch = new( order => ['a', 'b', 'c', 'd', 'e'], __i => 2 );
                is_deeply $ch->order, ['a', 'b', 'c', 'd', 'e'];
                is $ch->__size, 5;
                is $ch->__i, 2;
            } 'valid';

            dies_ok {
                my $ch = new( order => 'abcde', __i => 5 );
            } '__i: should be less than size of "order"';
        };
    };

    subtest 'has upper' => sub {
        subtest 'false' => sub {
            my $ch = new( order => 'abc' );
            ok ! defined $ch->upper;
            ok ! $ch->has_upper();
        };

        subtest 'true' => sub {
            my $upper = new( order => 'abc' );
            my $ch = new( order => 'xyz', upper => $upper );
            ok defined $ch->upper;
            ok $ch->has_upper();
        };
    };
};

subtest 'set' => sub {
    my $ch = new( order => 'abc', set => 'c' );
    is "$ch", 'c';
    is $ch->__i, 2;
    dies_ok {
        $ch->set();
    } 'should not be available as getter';
};

done_testing;

