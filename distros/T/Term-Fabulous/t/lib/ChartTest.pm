package ChartTest;

# Helpers for the chart widget tests: build a chart of a fixed size, draw
# it without a terminal and read back its cells, or put it on a memory
# terminal and move the mouse pointer over it.

use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT = qw(sized draw glyph_row fg_at bg_at glyph_at rgb is_bold braille_dots cells_with bar_eighths hover_ui pointer_to hovers);    ## no critic (Modules::ProhibitAutomaticExportation) every test uses all helpers

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Render::Attr qw(cell_color_attr);
use Term::Fabulous::Static;
use Term::Fabulous::Termbox qw(TB_BOLD TB_MOD_MOTION TF_KEY_MOUSE_MOVE);
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;

my %EIGHTHS = map { ( substr( "\x{2581}\x{2582}\x{2583}\x{2584}\x{2585}\x{2586}\x{2587}\x{2588}", $_, 1 ) => $_ + 1 ) } 0 .. 7;

# A chart of the class, $width columns by $height rows.
sub sized ( $class, $width, $height, %args ) {
	return $class->new( %args, layout => { sizing => { width => sizing_fixed($width), height => sizing_fixed($height) } } );
}

# Draws the chart as the root of a static page; returns its rows as text
# (trailing spaces dropped). The chart's cells show the frame afterwards.
sub draw ($chart) {
	return Term::Fabulous::Static->new( root => $chart, width => 200 )->render_lines( colors => 0 );
}

sub _cell ( $chart, $x, $y ) {
	return $chart->cell( $x, $y );
}

# The glyphs of a row, unset cells as spaces.
sub glyph_row ( $chart, $y ) {
	return join '', map { my $cell = _cell( $chart, $_, $y ); defined $cell ? $cell->[0] : ' ' } 0 .. $chart->columns - 1;
}

sub glyph_at ( $chart, $x, $y ) {
	my $cell = _cell( $chart, $x, $y ) // return undef;
	return $cell->[0];
}

# The colors of a cell without the style bits, comparable to rgb().
sub fg_at ( $chart, $x, $y ) {
	my $cell = _cell( $chart, $x, $y ) // return undef;
	return defined $cell->[1] ? $cell->[1] & ~TB_BOLD : undef;
}

sub bg_at ( $chart, $x, $y ) {
	my $cell = _cell( $chart, $x, $y ) // return undef;
	return $cell->[2];
}

sub is_bold ( $chart, $x, $y ) {
	my $cell = _cell( $chart, $x, $y ) // return 0;
	return defined $cell->[1] && $cell->[1] & TB_BOLD ? 1 : 0;
}

# A color as the cells hold it.
sub rgb ($color) {
	return cell_color_attr( color => $color );
}

# The number of Braille dots in the chart's cells.
sub braille_dots ($chart) {
	my $dots = 0;
	foreach my $y ( 0 .. $chart->rows - 1 ) {
		foreach my $x ( 0 .. $chart->columns - 1 ) {
			my $glyph = glyph_at( $chart, $x, $y ) // next;
			my $code  = ord $glyph;
			next unless $code >= 0x2800 && $code <= 0x28FF;
			$dots += unpack '%32b*', chr( $code - 0x2800 );
		}
	}
	return $dots;
}

# The cells [x, y] for which the test returns true; it gets the chart, x
# and y.
sub cells_with ( $chart, $test ) {
	my @found;
	foreach my $y ( 0 .. $chart->rows - 1 ) {
		push @found, map { [ $_, $y ] } grep { $test->( $chart, $_, $y ) } 0 .. $chart->columns - 1;
	}
	return @found;
}

# How high a vertical bar of the color is in column $x, in eighths of a
# cell: full cells, the eighth blocks on top and the upper half block on
# the baseline row; a block's other part is its background.
sub bar_eighths ( $chart, $x, $color ) {
	my $eighths = 0;
	foreach my $y ( 0 .. $chart->rows - 1 ) {
		my $glyph = glyph_at( $chart, $x, $y )                  // next;
		my $part  = $glyph eq "\x{2580}" ? 4 : $EIGHTHS{$glyph} // 0;
		$eighths += $part if ( fg_at( $chart, $x, $y ) // -1 ) == $color;
		$eighths += $part ? 8 - $part : 8 if ( bg_at( $chart, $x, $y ) // -1 ) == $color;
	}
	return $eighths;
}

# The chart in the top left corner of a 40x20 memory terminal, drawn once;
# a harness with the terminal, the UI and the SeriesHover events, which
# go on to the chart's ancestors.
sub hover_ui ($chart) {
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($chart);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 20 );
	my $ui       = Term::Fabulous->new( root => $root, width => 40, height => 20, terminal => $terminal );
	my %h        = ( chart => $chart, root => $root, terminal => $terminal, ui => $ui, events => [] );
	my $continue = Clay::UI::Enum::Result->CONTINUE;
	$chart->on( SeriesHover => sub ($event) { push $h{events}->@*, $event; return $continue } );
	$ui->step;
	return \%h;
}

# Moves the pointer onto a cell of the chart (or anywhere on the terminal
# with screen => 1) and draws the frame.
sub pointer_to ( $h, $x, $y, %options ) {
	my ( $origin_x, $origin_y ) = $options{screen} ? ( 0, 0 ) : $h->{chart}->content_origin;
	$h->{terminal}->mouse( key => TF_KEY_MOUSE_MOVE, x => $origin_x + $x, y => $origin_y + $y, mod => TB_MOD_MOTION );
	$h->{ui}->step;
	return;
}

# The SeriesHover events since the last call, as hashes of their defined
# values.
sub hovers ($h) {
	my @events = map {
		my $event = $_;
		+{ map { defined $event->$_ ? ( $_ => $event->$_ ) : () } qw(series index label value x) }
	} $h->{events}->@*;
	$h->{events} = [];
	return \@events;
}

1;
