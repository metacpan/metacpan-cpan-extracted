use strict;
use warnings;
use Prima qw(Application Cairo);

sub cr_paint
{
	my ($cr, $w, $h) = @_;
	my $d = 20;
	return if $w / 2 < $d || $h / 2 < $d;
	$cr-> move_to( $d, $d );
	$cr-> line_to( $w - $d, $h - $d );
	$cr-> stroke;

	# don't use set_font_size, because it overrides the matrix
	my $matrix = $cr-> get_font_matrix;
	$matrix->scale(1.8, 1.8);
	$cr->set_font_matrix($matrix);

	$cr-> move_to( $d * 2, $d );
	$cr-> show_text("(0,0)");
	my $tx = $cr->text_extents("(1,1)");
	$cr-> move_to($w - $d * 3 - $tx->{width}, $h - $d );
	$cr-> show_text("(1,1)");
	$cr-> stroke;

	$cr-> save;
	$cr-> translate($w - $d * 3 - $tx->{width}, $h - $d );
	$cr-> move_to(0,-2);
	$cr-> line_to(0,-2+$tx->{height});
	$cr-> line_to($tx->{width},-2+$tx->{height});
	$cr-> stroke;
	$cr-> restore;

	$cr-> save;
	$cr-> translate($d, $d);
	$cr-> scale( map { $d / 4 } 0, 1);
	$cr-> arc(0,0,1,0,6.28);
	$cr-> fill;
	$cr-> restore;

	$cr-> translate($w - $d, $h - $d );

	$cr-> rotate( 3.14 + atan2($h - 2 * $d, $w - 2 * $d));
	$cr-> move_to( 0,0);
	$cr-> line_to( map { $d / 2 } 0, 1);
	$cr-> stroke;

	$cr-> rotate( -1.57);
	$cr-> move_to( 0,0);
	$cr-> line_to( map { $d / 2 } 0, 1);
	$cr-> stroke;

}

Prima::MainWindow->new( text => 'Transform', onPaint => sub {
	my $self = shift;
	$self->clear;
	my @sz = $self-> size;
	$self-> color(cl::Blue);
	$self-> line( 0, $sz[1]/2, $sz[0], $sz[1]/2);
	$self-> text_out( "transform => 'cairo'", 10, $sz[1]/2 + 10);
	$self-> text_out( "transform => 'prima'", 10, $sz[1]/2 - 10 - $self->font->height );

	my $cr;
	$cr = $self->cairo_context( transform => 'cairo' );
	cr_paint( $cr, $sz[0], $sz[1] / 2, "transform => cairo" );

	$cr = $self->cairo_context( transform => 'prima' );
	cr_paint( $cr, $sz[0], $sz[1] / 2, "transform => prima" );
} );

run Prima;
