package OpenGL::Sandbox::V1::Quadric;
BEGIN { $OpenGL::Sandbox::V1::Quadric::VERSION = '0.02'; }
require OpenGL::Sandbox::V1; # automatically loads Quadric via XS

# ABSTRACT - Rendering parameters for various geometric shapes

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::V1::Quadric

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  default_quadric->normals(GLU_SMOOTH)->texture(1)->sphere(100, 42, 42);

=head1 DESCRIPTION

GLU Quadrics are a funny name for a small object that holds a few rendering parameters for
another few geometry-plotting functions.  They provide a quick/convenient way to render some
simple solids without messing with a bunch of trigonometry and loops.

=head1 CONFIGURATION

Each of these is write-only.  They return the object for convenient chaining.

=head2 draw_style

  $q->draw_style($x)  # GLU_FILL, GLU_LINE, GLU_SILHOUETTE, GL_POINT

You can also use aliases of:

=over

=item C<draw_fill>

=item C<draw_line>

=item C<draw_silhouette>

=item C<draw_point>

=back

=head2 normals

  $q->normals($x)  # GLU_NONE, GLU_FLAT, GLU_SMOOTH

You can also use aliases of:

=over

=item C<no_normals>, or normals(0)

=item C<flat_normals>

=item C<smooth_normals>

=back

=head2 orientation

  $q->orientation($x)   # GLU_OUTSIDE, GLU_INSIDE

You can also use aliases of

=over

=item C<inside>

=item C<outside>

=back

=head2 texture

  $q->texture($bool)    # GL_TRUE, GL_FALSE

=head1 GEOMETRY PLOTTING

=head2 sphere

  $q->sphere($radius, $slices, $stacks);

Plot a sphere around the origin with specified dimensions.

=head2 cylinder

  $q->cyliner($base, $top, $height, $slices, $stacks);

Plot a cylinder along the Z axis with the specified dimensions.

=head2 disk

  $q->disk($inner, $outer, $slices, $stacks);

"disk" is slightly misleading; it is a cylinder with a hole through the center.
A solid disk would actually be generated with the L</cylinder> method.

=head2 partial_disk

  $q->partial_disk($inner, $outer, $slices, $loops, $start, $sweep);

Plot a wedge of a disk around the Z axis.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
