#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests
  name     => 'multimethods',
  requires => { 'Syntax::Keyword::MultiSub' => '0.02' },
  version  => v5.26.0;

package My::Point {
    use MooseX::Extended types => [qw/Num/];
    param [ 'x', 'y' ] => ( isa => Num );
}

package My::Point::3D {
    use MooseX::Extended types => [qw/Num/];
    extends 'My::Point';
    param 'z' => ( isa => Num );
}

package My::Multi {
    use MooseX::Extended includes => [qw/multi/];

    multi sub point ( $self, $x, $y ) {
        return My::Point->new( x => $x, y => $y );
    }
    multi sub point ( $self, $x, $y, $z ) {
        return My::Point::3D->new( x => $x, y => $y, z => $z );
    }
}

package My::Multi::Role {
    use MooseX::Extended::Role includes => [qw/multi/];

    multi sub point ( $self, $x, $y ) {
        return My::Point->new( x => $x, y => $y );
    }
    multi sub point ( $self, $x, $y, $z ) {
        return My::Point::3D->new( x => $x, y => $y, z => $z );
    }
}

package My::Class::Consuming::The::Role {
    use MooseX::Extended;
    with 'My::Multi::Role';
}

my %cases = (
    classes => 'My::Multi',
    roles   => 'My::Class::Consuming::The::Role',
);

while ( my ( $name, $class ) = each %cases ) {
    subtest "Multi in $name" => sub {
        ok my $multi = $class->new, "We should be allowed to load $name with multimethods";

        subtest '2d point' => sub {
            ok my $point = $multi->point( 3, 4 ), 'We can fetch a 2d point';
            ok $point->isa('My::Point'),          '... and it should be the correct class';
            ok !$point->isa('My::Point::3D'),     '... and definitely not the wrong class';
            is $point->x, 3, '... with the correct x';
            is $point->y, 4, '... and the correct y';
            ok !$point->can('z'), '... and it does not have a z attribute';
        };

        subtest '3d point' => sub {
            ok my $point = $multi->point( 5, 6, 7 ), 'We can fetch a 3d point';
            ok $point->isa('My::Point'),             '... and it should be the correct class';
            ok $point->isa('My::Point::3D'),         '... and t should be the corect class';
            is $point->x, 5, '... with the correct x';
            is $point->y, 6, '... and the correct y';
            is $point->z, 7, '... and the correct z';
        };

        explain 'We would need to defind `multi sub point( $self, $x );` for this to work';
        throws_ok { $multi->point(1); }
        qr/Unable to find a function body for a call to .*? having 2 arguments/,
          'Multimethods whose arguments do not match will fail';
    };
}

done_testing;
