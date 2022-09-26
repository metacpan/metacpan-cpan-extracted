use lib 't/lib';
use MooseX::Extended::Tests;

package My::Point::Moose {
    use Moose;
    has 'x' => ( is => 'ro', isa => 'Num', required => 1 );
    has 'y' => ( is => 'ro', isa => 'Num', required => 0, default => 0 );
}

package My::Point::Moose::Mutable {
    use Moose;
    extends 'My::Point::Moose';
    has '+x' => ( clearer => 'clear_x', writer => 'set_x' );
    has '+y' => ( clearer => 'clear_y', writer => 'set_y' );
}

package My::Point {
    use MooseX::Extended types => ['Num'];
    param 'x' => ( isa => Num );
    field 'y' => ( isa => Num, default => 0 );
}

package My::Point::Mutable {
    use MooseX::Extended;
    extends 'My::Point';
    param '+x' => ( clearer => 1, writer => 1 );
    field '+y' => ( clearer => 1, writer => 1 );
}

for my $class ( 'My::Point::Moose', 'My::Point' ) {
    subtest $class => sub {

        ok( my $p1 = $class->new( x => 1 ),              "the parent class can be instantiated" );
        ok( my $p2 = "${class}::Mutable"->new( x => 1 ), "... and the child class too" );

        is( $p1->y, 0, "the default field value is applied in the parent class" );
        is( $p2->y, 0, "... and in the child class" );

        lives_ok { $p2->set_x(0) } "the child class can mutate its param";
        throws_ok { $p1->set_x(0) } qr{Can't locate object method "set_x"}, "... but the parent can't";

        lives_ok { $p2->set_y(1) } "the child class can mutate its field";
        throws_ok { $p1->set_y(1) } qr{Can't locate object method "set_y"}, "... but the parent can't";

        throws_ok { $class->new( x => 'foo' ) }
        qr{type constraint.*Num},
          "the param type constraint is enforced in the parent class";
        throws_ok { "${class}::Mutable"->new( x => 'foo' ) }
        qr{type constraint.*Num},
          "... and in the child class";
    }
}

done_testing();