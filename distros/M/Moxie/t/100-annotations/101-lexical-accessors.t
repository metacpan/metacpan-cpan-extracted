#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

package Point {
    use Moxie;

    extends 'Moxie::Object';

    has '$!x' => sub { 0 };
    has '$!y' => sub { 0 };

    my sub _x : private('$!x');
    my sub _y : private('$!y');

    sub BUILDARGS : init_args(
        x => '$!x',
        y => '$!y',
    );

    sub x : ro('$!x');
    sub y : ro('$!y');

    sub clear ($self) {
        (_x, _y) = (0, 0);
    }

    sub pack ($self) {
        +{ x => _x, y => _y }
    }
}

# ... subclass it ...

package Point3D {
    use Moxie;

    extends 'Point';

    has '$!z' => sub { 0 };

    my sub _z : private('$!z');

    sub BUILDARGS : init_args( z => '$!z' );

    sub z : ro('$!z');

    sub clear ($self) {
        $self->next::method;
        _z = 0;
    }

    sub pack ($self) {
        my $data = $self->next::method;
        $data->{z} = _z;
        $data;
    }
}

## Test an instance
subtest '... test an instance of Point' => sub {
    my $p = Point->new;
    isa_ok($p, 'Point');

    is $p->x, 0, '... got the default value for x';
    is $p->y, 0, '... got the default value for y';

    is_deeply $p->pack, { x => 0, y => 0 }, '... got the right value from pack';
};

subtest '... test an instance of Point with args' => sub {
    my $p = Point->new( x => 10, y => 20 );
    isa_ok($p, 'Point');

    is $p->x, 10, '... got the expected value for x';
    is $p->y, 20, '... got the expected value for y';

    is_deeply $p->pack, { x => 10, y => 20 }, '... got the right value from pack';

    $p->clear;

    is $p->x, 0, '... got the cleared value for x';
    is $p->y, 0, '... got the cleared value for y';

    is_deeply $p->pack, { x => 0, y => 0 }, '... got the right value from pack';
};

## Test the instance
subtest '... test an instance of Point3D' => sub {
    my $p3d = Point3D->new();
    isa_ok($p3d, 'Point3D');
    isa_ok($p3d, 'Point');

    is $p3d->x, 0, '... got the default value for x';
    is $p3d->y, 0, '... got the default value for y';
    is $p3d->z, 0, '... got the default value for z';

    is_deeply $p3d->pack, { x => 0, y => 0, z => 0 }, '... got the right value from pack';
};

subtest '... test an instance of Point3D with args' => sub {
    my $p3d = Point3D->new( x => 1, y => 2, z => 3 );
    isa_ok($p3d, 'Point3D');
    isa_ok($p3d, 'Point');

    is $p3d->x, 1, '... got the supplied value for x';
    is $p3d->y, 2, '... got the supplied value for y';
    is $p3d->z, 3, '... got the supplied value for z';

    is_deeply $p3d->pack, { x => 1, y => 2, z => 3 }, '... got the right value from pack';

    $p3d->clear;

    is $p3d->x, 0, '... got the default value for x';
    is $p3d->y, 0, '... got the default value for y';
    is $p3d->z, 0, '... got the default value for z';

    is_deeply $p3d->pack, { x => 0, y => 0, z => 0 }, '... got the right value from pack';
};

done_testing;


