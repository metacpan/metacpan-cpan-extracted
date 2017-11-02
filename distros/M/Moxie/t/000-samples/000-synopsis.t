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

    has x => ( default => sub { 0 } );
    has y => ( default => sub { 0 } );

    sub x : ro;
    sub y : ro;

    sub clear ($self) {
        $self->@{ 'x', 'y' } = (0, 0);
    }
}

# ... subclass it ...

package Point3D {
    use Moxie;

    extends 'Point';

    has z => ( default => sub { 0 } );

    sub z : ro;

    sub clear ($self) {
        $self->next::method;
        $self->{z} = 0;
    }
}

## Test an instance
subtest '... test an instance of Point' => sub {
    my $p = Point->new;
    isa_ok($p, 'Point');

    is $p->x, 0, '... got the default value for x';
    is $p->y, 0, '... got the default value for y';
};

subtest '... test an instance of Point with args' => sub {
    my $p = Point->new( x => 10, y => 20 );
    isa_ok($p, 'Point');

    is $p->x, 10, '... got the expected value for x';
    is $p->y, 20, '... got the expected value for y';

    $p->clear;

    is $p->x, 0, '... got the default value for x';
    is $p->y, 0, '... got the default value for y';
};

## Test the instance
subtest '... test an instance of Point3D' => sub {
    my $p3d = Point3D->new();
    isa_ok($p3d, 'Point3D');
    isa_ok($p3d, 'Point');

    is $p3d->x, 0, '... got the default value for x';
    is $p3d->y, 0, '... got the default value for y';
    is $p3d->z, 0, '... got the default value for z';
};

subtest '... test an instance of Point3D with args' => sub {
    my $p3d = Point3D->new( x => 1, y => 2, z => 3 );
    isa_ok($p3d, 'Point3D');
    isa_ok($p3d, 'Point');

    is $p3d->x, 1, '... got the supplied value for x';
    is $p3d->y, 2, '... got the supplied value for y';
    is $p3d->z, 3, '... got the supplied value for z';

    $p3d->clear;

    is $p3d->x, 0, '... got the default value for x';
    is $p3d->y, 0, '... got the default value for y';
    is $p3d->z, 0, '... got the default value for z';
};

done_testing;


