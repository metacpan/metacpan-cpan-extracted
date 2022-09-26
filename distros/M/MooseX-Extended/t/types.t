#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests;

package My::Standard {
    use MooseX::Extended types => [ ':Standard', 'compile' ];
    use List::Util 'sum';

    param name => ( isa => Str );
    param int  => ( isa => Int );

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [Num] );
        ($args) = $check->($args);
        return sum( $args->@* );
    }
}

subtest 'Types::Standard' => sub {
    my $object = My::Standard->new(
        name => 'example',
        int  => 42,
    );
    is $object->name,                     'example', 'We should be able to import basic :Standard types';
    is $object->int,                      42,        '... and they work as expected';
    is $object->add( [ 4, .5, .5, -3 ] ), 2,         '... and we can combine this with other imported functions';
};

package My::Numeric {
    use MooseX::Extended types => [ ':Numeric', qw/compile ArrayRef/ ];
    use List::Util 'sum';

    param int          => ( isa => Int );
    param negative_num => ( isa => NegativeNum );

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [ Num, 1 ] );
        ($args) = $check->($args);
        return sum( $args->@* );
    }
}

subtest 'Types::Common::Numeric' => sub {
    my $object = My::Numeric->new(
        int          => 4,
        negative_num => -3.14,
    );
    is $object->int,                      4,     'We should be able to import basic :Numeric types';
    is $object->negative_num,             -3.14, '... and the extended ones';
    is $object->add( [ 4, .5, .5, -3 ] ), 2,     '... and we can combine this with other imported functions';
};

package My::String {
    use MooseX::Extended types => [ ':String', qw/compile ArrayRef Num/ ];
    use List::Util 'sum';

    param num  => ( isa => Num );
    param name => ( isa => NonEmptyStr );

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [ Num, 1 ] );
        ($args) = $check->($args);
        return sum( $args->@* );
    }
}

subtest 'Types::Common::String' => sub {
    my $object = My::String->new(
        name => 'example',
        num  => -3.14,
    );
    is $object->name,                     'example', 'We should be able to import basic :String types';
    is $object->num,                      -3.14,     '... or additional types we explicitly name';
    is $object->add( [ 4, .5, .5, -3 ] ), 2,         '... and we can combine this with other imported functions';
};

done_testing;
