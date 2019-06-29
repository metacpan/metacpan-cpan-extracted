package Term::Caca::FFI;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: ffi bindings to libcaca
$Term::Caca::FFI::VERSION = '3.1.0';

use 5.20.0;

use Alien::caca;

use FFI::Platypus 0.88;

use Exporter::Shiny qw/
    UINT_SIZE
    caca_clear_canvas
    caca_create_display
    caca_create_canvas
    caca_create_display_with_driver
    caca_draw_box
    caca_draw_circle
    caca_draw_ellipse
    caca_draw_line
    caca_draw_polyline
    caca_draw_thin_box
    caca_draw_thin_ellipse
    caca_draw_thin_line
    caca_draw_thin_polyline
    caca_draw_thin_triangle
    caca_draw_triangle
    caca_export_canvas_to_memory
    caca_fill_box
    caca_fill_ellipse
    caca_fill_triangle
    caca_get_canvas
    caca_get_canvas_height
    caca_get_canvas_width
    caca_get_display_driver_list
    caca_get_display_time
    caca_get_event
    caca_get_event_key_ch
    caca_get_event_mouse_button
    caca_get_event_mouse_x
    caca_get_event_mouse_y
    caca_get_event_resize_height
    caca_get_event_resize_width
    caca_get_event_type
    caca_get_mouse_x
    caca_get_mouse_y
    caca_put_char
    caca_put_str
    caca_refresh_display
    caca_set_color_ansi
    caca_set_color_argb
    caca_set_display_time
    caca_set_display_title
/;

my $ffi = FFI::Platypus->new;
$ffi->lib(Alien::caca->dynamic_libs);

$ffi->load_custom_type('::StringArray' => 'string_array');

$ffi->attach( 'caca_get_event' => ['opaque','int','opaque','int'] => 'void' );
$ffi->attach( 'caca_get_display_driver_list' => [] => 'string_array' );
$ffi->attach( 'caca_create_display_with_driver' => [ 'opaque', 'string' ] => 'opaque' );
$ffi->attach( 'caca_create_display' => [ 'opaque' ] => 'opaque' );
$ffi->attach( 'caca_create_canvas' => [ 'int', 'int'] => 'opaque' );
$ffi->attach( 'caca_set_display_title' => [ 'opaque', 'string' ] => 'int' );
$ffi->attach( 'caca_set_display_time' => [ 'opaque', 'int' ] => 'int' );
$ffi->attach( 'caca_get_display_time' => [ 'opaque' ] => 'int' );
$ffi->attach( 'caca_get_canvas' => [ 'opaque' ] => 'opaque' );
$ffi->attach( 'caca_set_color_argb' => [ 'opaque', 'int' ] => 'opaque' );
$ffi->attach( 'caca_put_char' => [ 'opaque', 'int', 'int', 'char' ] => 'void' );
$ffi->attach( 'caca_put_str' => [ 'opaque', 'int', 'int', 'string' ] => 'void' );
$ffi->attach( 'caca_refresh_display' => [ 'opaque' ] => 'opaque' );
$ffi->attach( 'caca_get_mouse_x' => ['opaque'] => 'int' );
$ffi->attach( 'caca_get_mouse_y' => ['opaque'] => 'int' );
$ffi->attach( 'caca_fill_triangle' => ['opaque', ( 'int' ) x 6, 'char' ] => 'void' );
$ffi->attach( 'caca_draw_triangle' => ['opaque', ( 'int' ) x 6, 'char' ] => 'void' );
$ffi->attach( 'caca_draw_thin_triangle' => ['opaque', ( 'int' ) x 6 ] => 'void' );
$ffi->attach( 'caca_clear_canvas' => ['opaque'] => 'void' );
$ffi->attach( 'caca_fill_box' => ['opaque', ( 'int' ) x 4, 'char' ] => 'void' );
$ffi->attach( 'caca_draw_box' => ['opaque', ( 'int' ) x 4, 'char' ] => 'void' );
$ffi->attach( 'caca_draw_thin_box' => ['opaque', ( 'int' ) x 4 ] => 'void' );
$ffi->attach( 'caca_fill_ellipse' => ['opaque', ( 'int' ) x 4, 'char' ] => 'void' );
$ffi->attach( 'caca_draw_ellipse' => ['opaque', ( 'int' ) x 4, 'char' ] => 'void' );
$ffi->attach( 'caca_draw_thin_ellipse' => ['opaque', ( 'int' ) x 4 ] => 'void' );
$ffi->attach( 'caca_draw_circle' => ['opaque', ( 'int' ) x 3, 'char' ] => 'void' );

$ffi->attach( 'caca_draw_polyline' => ['opaque', 'int[]', 'int[]', 'int', 'char' ] => 'void' );
$ffi->attach( 'caca_draw_thin_polyline' => ['opaque', 'int[]', 'int[]', 'int' ] => 'void' );

$ffi->attach( 'caca_draw_line' => ['opaque', ( 'int' ) x 4, 'char' ] => 'void' );
$ffi->attach( 'caca_draw_thin_line' => ['opaque', ( 'int' ) x 4, 'char' ] => 'void' );

$ffi->attach( 'caca_get_canvas_width' => ['opaque'] => 'int' );
$ffi->attach( 'caca_get_canvas_height' => ['opaque'] => 'int' );

$ffi->attach( 'caca_export_canvas_to_memory' => [ 'opaque', 'string', 'opaque' ]
        => 'string' );

$ffi->attach( caca_set_color_ansi => [ 'opaque', 'int', 'int' ] => 'void' );
$ffi->attach( caca_get_event_type => [ 'opaque' ] => 'int' );
$ffi->attach( caca_get_event_key_ch => [ 'opaque' ] => 'char' );

$ffi->attach( caca_get_event_mouse_x => [ 'opaque' ] => 'int' );
$ffi->attach( caca_get_event_mouse_y => [ 'opaque' ] => 'int' );
$ffi->attach( caca_get_event_resize_width => [ 'opaque' ] => 'int' );
$ffi->attach( caca_get_event_resize_height => [ 'opaque' ] => 'int' );

$ffi->attach( caca_get_event_mouse_button => [ 'opaque' ] => 'int' );

our $pointer_size = $ffi->sizeof( 'void *' );

sub UINT_SIZE {
    state $size = $ffi->sizeof( 'uint' );
    return $size;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Caca::FFI - ffi bindings to libcaca

=head1 VERSION

version 3.1.0

=head1 DESCRIPTION

Internal bindings to the libcaca functions. Nothing
interesting to see here for users.

=head1 AUTHORS

=over 4

=item *

John Beppu <beppu@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019, 2018, 2013, 2011 by John Beppu.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut
