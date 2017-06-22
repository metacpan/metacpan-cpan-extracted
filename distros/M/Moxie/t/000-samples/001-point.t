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

    has _x => sub { 0 };
    has _y => sub { 0 };

    my sub _x : private;
    my sub _y : private;

    sub BUILDARGS : init_args(
        x => '_x',
        y => '_y',
    );

    sub x : ro('_x');
    sub y : ro('_y');

    sub set_x : wo('_x');
    sub set_y : wo('_y');

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

    has _z => sub { 0 };

    my sub _z : private;

    sub BUILDARGS : init_args( z => '_z' );

    sub z     : ro('_z');
    sub set_z : wo('_z');

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

    is_deeply(
        mro::get_linear_isa('Point'),
        [ 'Point', 'Moxie::Object', 'UNIVERSAL::Object' ],
        '... got the expected linear isa'
    );

    is $p->x, 0, '... got the default value for x';
    is $p->y, 0, '... got the default value for y';

    $p->set_x(10);
    is $p->x, 10, '... got the right value for x';

    $p->set_y(320);
    is $p->y, 320, '... got the right value for y';

    is_deeply $p->pack, { x => 10, y => 320 }, '... got the right value from pack';
};

subtest '... test an instance of Point with args' => sub {
    my $p = Point->new( x => 10, y => 20 );
    isa_ok($p, 'Point');

    is_deeply(
        mro::get_linear_isa('Point'),
        [ 'Point', 'Moxie::Object', 'UNIVERSAL::Object' ],
        '... got the expected linear isa'
    );

    is $p->x, 10, '... got the expected value for x';
    is $p->y, 20, '... got the expected value for y';

    $p->set_x(10);
    is $p->x, 10, '... got the right value for x';

    $p->set_y(320);
    is $p->y, 320, '... got the right value for y';

    is_deeply $p->pack, { x => 10, y => 320 }, '... got the right value from pack';
};

## Test the instance
subtest '... test an instance of Point3D' => sub {
    my $p3d = Point3D->new();
    isa_ok($p3d, 'Point3D');
    isa_ok($p3d, 'Point');

    is_deeply(
        mro::get_linear_isa('Point3D'),
        [ 'Point3D', 'Point', 'Moxie::Object', 'UNIVERSAL::Object' ],
        '... got the expected linear isa'
    );

    is $p3d->z, 0, '... got the default value for z';

    $p3d->set_x(10);
    is $p3d->x, 10, '... got the right value for x';

    $p3d->set_y(320);
    is $p3d->y, 320, '... got the right value for y';

    $p3d->set_z(30);
    is $p3d->z, 30, '... got the right value for z';

    is_deeply $p3d->pack, { x => 10, y => 320, z => 30 }, '... got the right value from pack';
};

subtest '... test an instance of Point3D with args' => sub {
    my $p3d = Point3D->new( x => 1, y => 2, z => 3 );
    isa_ok($p3d, 'Point3D');
    isa_ok($p3d, 'Point');

    is_deeply(
        mro::get_linear_isa('Point3D'),
        [ 'Point3D', 'Point', 'Moxie::Object', 'UNIVERSAL::Object' ],
        '... got the expected linear isa'
    );

    is $p3d->x, 1, '... got the supplied value for x';
    is $p3d->y, 2, '... got the supplied value for y';
    is $p3d->z, 3, '... got the supplied value for z';

    $p3d->set_x(10);
    is $p3d->x, 10, '... got the right value for x';

    $p3d->set_y(320);
    is $p3d->y, 320, '... got the right value for y';

    $p3d->set_z(30);
    is $p3d->z, 30, '... got the right value for z';

    is_deeply $p3d->pack, { x => 10, y => 320, z => 30 }, '... got the right value from pack';
};

subtest '... meta test' => sub {

    my @MOP_object_methods = qw[
        new BUILDARGS CREATE DESTROY
    ];

    my @Point_methods = qw[
        x set_x
        y set_y
        pack
        clear
    ];

    my @Point3D_methods = qw[
        z set_z
        clear
    ];

    subtest '... test Point' => sub {

        my $Point = MOP::Class->new( name => 'Point' );
        isa_ok($Point, 'MOP::Class');
        isa_ok($Point, 'UNIVERSAL::Object');

        is_deeply($Point->mro, [ 'Point', 'Moxie::Object', 'UNIVERSAL::Object' ], '... got the expected mro');
        is_deeply([ $Point->superclasses ], [ 'Moxie::Object' ], '... got the expected superclasses');

        foreach ( @Point_methods ) {
            ok($Point->has_method( $_ ), '... Point has method ' . $_);

            my $m = $Point->get_method( $_ );
            isa_ok($m, 'MOP::Method');
            is($m->name, $_, '... got the right method name (' . $_ . ')');
            ok(!$m->is_required, '... the ' . $_ . ' method is not a required method');
            is($m->origin_stash, 'Point', '... the ' . $_ . ' method was defined in Point class')
        }

        ok(Point->can( $_ ), '... Point can call method ' . $_)
            foreach @MOP_object_methods, @Point_methods;

        {
            my $m = $Point->get_method( 'set_y' );
            is_deeply([ $m->get_code_attributes ], ['wo(\'_y\')'], '... we show one CODE attribute');
        }

        {
            my $m = $Point->get_method( 'y' );
            is_deeply([ $m->get_code_attributes ], ['ro(\'_y\')'], '... we show one CODE attribute');
        }

    };

};

done_testing;


