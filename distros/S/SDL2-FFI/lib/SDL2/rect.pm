package SDL2::rect {
    use strict;
    use SDL2::Utils;
    use experimental 'signatures';
    use FFI::C::ArrayDef;
    #
    use SDL2::stdinc;
    use SDL2::error;
    use SDL2::pixels;
    use SDL2::rwops;
    #
    package SDL2::Point {
        use SDL2::Utils;
        our $TYPE =    # Store it
            has
            x => 'int',
            y => 'int';
        our $LIST = FFI::C::ArrayDef->new(
            ffi(),
            name    => 'PointList_t',
            class   => 'PointList',
            members => [$SDL2::Point::TYPE]
        );
    };

    package SDL2::FPoint {
        use SDL2::Utils;
        our $TYPE =    # Store it
            has x => 'float', y => 'float';
        our $LIST = FFI::C::ArrayDef->new(
            ffi(),
            name    => 'FPointList_t',
            class   => 'FPointList',
            members => [$SDL2::FPoint::TYPE]
        );
    };

    package SDL2::FRect {
        use SDL2::Utils;
        our $TYPE =    # Store it
            has x => 'float', y => 'float', w => 'float', h => 'float';
        our $LIST = FFI::C::ArrayDef->new(
            ffi(),
            name    => 'FRectList_t',
            class   => 'FRectList',
            members => [$SDL2::FRect::TYPE]
        );
    };

    package SDL2::Rect {
        use SDL2::Utils;
        our $TYPE =    # Store it
            has x => 'int', y => 'int', w => 'int', h => 'int';
        our $LIST = FFI::C::ArrayDef->new(
            ffi(),
            name    => 'RectList_t',
            class   => 'RectList',
            members => [$SDL2::Rect::TYPE]
        );
    };
    #
    define rect => [
        [   SDL_PointInRect => sub ( $p, $r ) {
                return ( ( $p->x >= $r->x ) &&
                        ( $p->x < ( $r->x + $r->w ) ) &&
                        ( $p->y >= $r->y ) &&
                        ( $p->y < ( $r->y + $r->h ) ) );
            }
        ],
        [   SDL_RectEmpty => sub ($r) {
                return ( ( !$r ) || ( $r->w <= 0 ) || ( $r->h <= 0 ) );
            }
        ],
        [   SDL_RectEquals => sub ( $l, $r ) {
                return ( $l &&
                        $r                 &&
                        ( $r->x == $l->x ) &&
                        ( $l->y == $r->y ) &&
                        ( $l->w == $r->w ) &&
                        ( $l->h == $r->h ) );
            }
        ],
    ];
    attach rect => {
        SDL_HasIntersection => [ [ 'SDL_Rect', 'SDL_Rect' ], 'SDL_bool' ],
        SDL_IntersectRect   => [ [ 'SDL_Rect', 'SDL_Rect', 'SDL_Rect' ], 'SDL_bool' ],
        SDL_UnionRect       => [ [ 'SDL_Rect', 'SDL_Rect', 'SDL_Rect' ] ],
        SDL_EnclosePoints   => [
            [ 'PointList_t', 'int', 'SDL_Rect', 'SDL_Rect' ],
            'SDL_bool' => sub ( $inner, $_points, $count, $clip, $result ) {
                my $points = $SDL2::Point::LIST->create(
                    [ map { { x => $_->x, y => $_->y } } @$_points ] );
                $inner->( $points, $count, $clip, $result );
            }
        ],
        SDL_IntersectRectAndLine => [ [ 'SDL_Rect', 'int*', 'int*', 'int*', 'int*' ], 'SDL_bool' ],
    };

=encoding utf-8

=head1 NAME

SDL2::rect - SDL2::Rect Management Functions

=head1 SYNOPSIS

    use SDL2 qw[:rect];

=head1 DESCRIPTION

This package defines functions used to manage L<SDL2::Rect> structures they may
be imported by name of with the given tag.


=head2 Functions

These functions may be imported with the C<:rect> tag.

=head2 C<SDL_PointInRect( ... )>

Find out if a given C<point> lies within a C<rectangle>.

    my $dot  = SDL2::Point->new( { x => 100, y => 100 } );
    my $box1 = SDL2::Rect->new( { x => 0,  y => 0, w => 50,  h => 50 } );
    my $box2 = SDL2::Rect->new( { x => 50, y => 0, w => 100, h => 101 } );
    printf "point %dx%d is %sside of box 1\n", $dot->x, $dot->y,
        SDL_PointInRect( $dot, $box1 ) ? 'in' : 'out';
    printf "point %dx%d is %sside of box 2\n", $dot->x, $dot->y,
        SDL_PointInRect( $dot, $box2 ) ? 'in' : 'out';

Expected parameters include:

=over

=item C<point> - an L<SDL2::Point> structure

=item C<rectangle> - an L<SDL2::Rect> structure

=back

Returns true if C<point> resides inside a C<rectangle>.

=head2 C<SDL_RectEmpty( ... )>

    my $box = SDL2::Rect->new( { w => 0, h => 100 } );
    printf 'box is %sempty', SDL_RectEmpty($box) ? '' : 'not ';

Expected parameters include:

=over

=item C<rectangle> - an L<SDL2::Rect> structure to query

=back

Returns true if the C<rectangle> has no area.

=head2 C<SDL_RectEquals( ... )>

Calculates whether or not two given rectangles are positionally and
dimensionally the same.

    my $box1 = SDL2::Rect->new( { w => 0, h => 100, x => 5 } );
    my $box2 = SDL2::Rect->new( { w => 0, h => 100, x => 10 } );
    my $box3 = SDL2::Rect->new( { w => 0, h => 100, x => 10 } );
    printf "box 1 is %sthe same as box 2\n", SDL_RectEquals( $box1, $box2 ) ? '' : 'not ';
    printf "box 2 is %sthe same as box 3\n", SDL_RectEquals( $box2, $box3 ) ? '' : 'not ';
    printf "box 3 is %sthe same as box 1\n", SDL_RectEquals( $box3, $box1 ) ? '' : 'not ';

Expected parameters include:

=over

=item C<lhs> - first L<SDL2::Rect> structure

=item C<rhs> - second L<SDL2::Rect> structure

=back

Returns a true value if the two rectangles are equal.

=head2 C<SDL_HasIntersection( ... )>

Determine whether two rectangles intersect.

    my $box1 = SDL2::Rect->new( { w => 10, h => 100, x => 5,   y => 10 } );
    my $box2 = SDL2::Rect->new( { w => 10, h => 100, x => 10,  y => 0 } );
    my $box3 = SDL2::Rect->new( { w => 10, h => 100, x => 100, y => 0 } );
    printf "box 1 %s box 2\n",
        SDL_HasIntersection( $box1, $box2 ) ? 'intersects' : 'does not intersect';
    printf "box 2 %s box 3\n",
        SDL_HasIntersection( $box2, $box3 ) ? 'intersects' : 'does not intersect';
    printf "box 3 %s box 1\n",
        SDL_HasIntersection( $box3, $box1 ) ? 'intersects' : 'does not intersect';

If either pointer is undef the function will return C<SDL_FALSE>.

Expected parameters include:

=over

=item C<lhs> - an L<SDL2::Rect> structure representing the first rectangle

=item C<rhs> - an L<SDL2::Rect> structure representing the second rectangle

=back

Returns C<SDL_TRUE> if there is an intersection, C<SDL_FALSE> otherwise.

=head2 C<SDL_IntersectRect( ... )>

Calculate the intersection of two rectangles.

    my $box1 = SDL2::Rect->new( { w => 10, h => 100, x => 5,  y => 10 } );
    my $box2 = SDL2::Rect->new( { w => 10, h => 100, x => 10, y => 0 } );
    my $res  = SDL2::Rect->new();
    printf 'the intersection of boxes 1 and 2 looks like { x => %d, y => %d, w => %d, h => %d }',
        $res->x, $res->y, $res->w, $res->h
        if SDL_IntersectRect( $box1, $box2, $res );

If C<result> is undef then this function will return C<SDL_FALSE>.

Expected parameters include:

=over

=item C<lhs> - an L<SDL2::Rect> structure representing the first rectangle

=item C<rhs> - an L<SDL2::Rect> structure representing the second rectangle

=item C<result> an L<SDL2::Rect> structure which will be filled in with the intersection of rectangles C<lhs> and C<rhs>

=back

Returns C<SDL_TRUE> if there is an intersection, C<SDL_FALSE> otherwise.

=head2 C<SDL_UnionRect( ... )>

Calculate the union of two rectangles.

    my $box1 = SDL2::Rect->new( { w => 10, h => 100, x => 5,  y => 10 } );
    my $box2 = SDL2::Rect->new( { w => 10, h => 100, x => 10, y => 0 } );
    my $res  = SDL2::Rect->new();
    SDL_UnionRect( $box1, $box2, $res );
    printf 'the union of boxes 1 and 2 looks like { x => %d, y => %d, w => %d, h => %d }', $res->x,
        $res->y, $res->w, $res->h;

Expected parameters include:

=over

=item C<lhs> - an L<SDL2::Rect> structure representing the first rectangle

=item C<rhs> - an L<SDL2::Rect> structure representing the second rectangle

=item C<result> an L<SDL2::Rect> structure which will be filled in with the intersection of rectangles C<lhs> and C<rhs>

=back

=head2 C<SDL_EnclosePoints( ... )>

Calculate a minimal rectangle enclosing a set of points.

    my $p1  = SDL2::Point->new( { x => 1, y => 10 } );
    my $p2  = SDL2::Point->new( { x => 5, y => 20 } );
    my $res = SDL2::Rect->new();
    printf 'points 1 and 2 are enclosed by a box like { x => %d, y => %d, w => %d, h => %d }',
        $res->x, $res->y, $res->w, $res->h
        if SDL_EnclosePoints( [ $p1, $p2 ], 2, undef, $res );

If C<clip> is not undef then only points inside of the clipping rectangle are
considered.

Expected parameters include:

=over

=item C<points> -  an array of L<SDL2::Point> structures representing points to be enclosed

=item C<count> - the number of structures in the C<points> array

=item C<clip> - an L<SDL2::Rect> used for clipping or C<undef> to enclose all points

=item C<result> - an L<SDL2::Rect> structure filled in with the minimal enclosing rectangle

=back

Returns C<SDL_TRUE> if any points were enclosed or C<SDL_FALSE> if all the
points were outside of the clipping rectangle.

=head2 C<SDL_IntersectRectAndLine( ... )>

Calculate the intersection of a rectangle and line segment.

    my $box = SDL2::Rect->new( { x => 0, y => 0, w => 32, h => 32 } );
    my $x1  = 0;
    my $y1  = 0;
    my $x2  = 31;
    my $y2  = 31;
    printf 'line fully inside rect was clipped: %d,%d - %d,%d', $x1, $y1, $x2, $y2
        if SDL_IntersectRectAndLine( $box, \$x1, \$y1, \$x2, \$y2 );

This function is used to clip a line segment to a rectangle. A line segment
contained entirely within the rectangle or that does not intersect will remain
unchanged. A line segment that crosses the rectangle at either or both ends
will be clipped to the boundary of the rectangle and the new coordinates saved
in C<X1>, C<Y1>, C<X2>, and/or C<Y2> as necessary.

Expected parameters include:

=over

=item C<rect> - an L<SDL2::Rect> structure representing the rectangle to intersect

=item C<X1> - a pointer to the starting X-coordinate of the line

=item C<Y1> - a pointer to the starting Y-coordinate of the line

=item C<X2> - a pointer to the ending X-coordinate of the line

=item C<Y2> - a pointer to the ending Y-coordinate of the line

=back

Returns C<SDL_TRUE> if there is an intersection, C<SDL_FALSE> otherwise.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords



=end stopwords

=cut

};
1;
