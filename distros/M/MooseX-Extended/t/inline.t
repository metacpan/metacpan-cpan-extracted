#!/usr/bin/env perl

use lib 't/lib';
use InlinePackages;    # provides My::Point and My::Point::Mutable
use MooseX::Extended::Tests;

explain <<'END';
This test verifies that we can inline several packages into one, and that we don't need the 
postfix block syntax. See t/lib/InlinePackages.pm
END

package My::Point::Moose {
    use v5.20.0;
    use Moose;
    use Types::Standard qw(Num HashRef);
    use MooseX::StrictConstructor;
    use feature qw( signatures postderef postderef_qq );
    no warnings qw( experimental::signatures experimental::postderef );
    use namespace::autoclean;
    use mro 'c3';

    has [ 'x', 'y' ] => ( is => 'ro', isa => Num );
    has session => ( is => 'ro', isa => HashRef, init_arg => undef, default => sub { { session => 1234 } } );

    sub session_id ($self) {
        my $session = $self->session;
        return "$session->@{session}";
    }
    __PACKAGE__->meta->make_immutable;
}

package My::Point::Mutable::Moose {
    use v5.20.0;
    use Moose;
    extends 'My::Point::Moose';
    use MooseX::StrictConstructor;
    use feature qw( signatures postderef postderef_qq );
    no warnings qw( experimental::signatures experimental::postderef );
    use namespace::autoclean;
    use mro 'c3';

    has '+x' => ( is => 'ro', writer => 'set_x', clearer => 'clear_x', default => 0 );
    has '+y' => ( is => 'ro', writer => 'set_y', clearer => 'clear_y', default => 0 );

    sub invert ($self) {
        my ( $x, $y ) = ( $self->x, $self->y );
        $self->set_x($y);
        $self->set_y($x);
    }

    __PACKAGE__->meta->make_immutable;
}

foreach my $class (qw/My::Point::Moose My::Point/) {
    subtest "moose and moosex should behave the same" => sub {
        subtest 'Read-only' => sub {
            my $point = $class->new( x => 7, y => 7.3 );
            is $point->x,          7,    'x should be correct';
            is $point->y,          7.3,  'y should be correct';
            is $point->session_id, 1234, "postderef_qq should work";

            throws_ok { $point->x(3) }
            'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
              'My::Point is immutable';
            is mro::get_mro($class), 'c3', "Our class's mro should be c3";
        };
    };
}

foreach my $class (qw/My::Point::Mutable::Moose My::Point::Mutable/) {
    subtest "moose and moosex should behave the same" => sub {
        subtest 'Read-write' => sub {
            my $point = $class->new( x => 7, y => 7.3 );
            is $point->x, 7,   'x should be correct';
            is $point->y, 7.3, 'y should be correct';

            throws_ok { $point->x(3) }
            'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
              'My::Point is immutable';

            $point->set_x(2);
            is $point->x,            2,    '... and our subclass can allow us to set the attributes';
            is mro::get_mro($class), 'c3', "Our class's mro should be c3";

            $point->invert;
            is $point->x, 7.3, 'x should be correct after inverting';
            is $point->y, 2,   'y should be correct after inverting';
        };
    };
}

done_testing;
