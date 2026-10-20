use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Object::Pad 0.825;

use Clay::XS qw(sizing_fixed sizing_grow CLAY_ATTACH_TO_PARENT CLAY_LEFT_TO_RIGHT);
use Term::Fabulous;
use Term::Fabulous::Role::Popup;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Display;

# A popup of 4 x 2 cells below its anchor, or nowhere while the test
# says it has no place.
class Test::Popup
	:isa(Term::Fabulous::Widget::Display)
	:does(Term::Fabulous::Role::Popup)
{
	use Term::Fabulous::Placement qw(place_popup);

	field $anchor :param :weak;
	field $is_known :param = 1;
	field $asked = 0;

	method popup_position () {
		$asked++;
		return undef unless $is_known;
		my $ui    = $self->ui                  // return undef;
		my $box   = $ui->bounding_box($anchor) // return undef;
		my $place = place_popup( anchor => $box, size => [ 4, 2 ], screen => [ $ui->width, $ui->height ] );
		return { x => $place->{x}, y => $place->{y} };
	}

	method contribute_floating :override ($config) {
		$self->SUPER::contribute_floating($config);
		$self->float_popup($config) if defined $config->{floating};
		return;
	}

	method asked () { return $asked }

	method natural_size () { return ( 4, 2 ) }

	method paint () { return }
}

# A row with a spacer and the anchor, on a 30 x 10 memory terminal.
sub popup_ui (%options) {
	my $root   = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_LEFT_TO_RIGHT, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $spacer = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(5), height => sizing_fixed(1) } } );
	my $anchor = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(6), height => sizing_fixed(1) } } );
	$root->add_child( $spacer, $anchor );
	my $ui = Term::Fabulous->new( root => $root, width => 30, height => 10, terminal => Term::Fabulous::Terminal::Memory->new( width => 30, height => 10 ) );
	$ui->step;
	my $popup = Test::Popup->new( anchor => $anchor, floating => { attach_to => CLAY_ATTACH_TO_PARENT, offset => { x => 2, y => 3 }, z_index => 9 }, %options );
	$anchor->add_child($popup);
	return ( $ui, $popup, $spacer );
}

subtest 'the popup floats from the root at its position' => sub {
	my ( $ui, $popup, $spacer ) = popup_ui();
	$ui->step;
	is $ui->bounding_box($popup), { x => 5, y => 1, width => 4, height => 2 }, 'below its anchor';

	$spacer->layout( { sizing => { width => sizing_fixed(12), height => sizing_fixed(1) } } );
	$ui->step;
	is $ui->bounding_box($popup), { x => 12, y => 1, width => 4, height => 2 }, 'it follows an anchor that moved in the same frame';

	my $asked = $popup->asked;
	is $ui->step,                   0,      'once it is in place, no frame is due';
	is $popup->asked,               $asked, 'and nobody asks';
	is $popup->floating->{z_index}, 9,      'its own floating hash keeps its z_index';
};

subtest 'without a position the popup floats as declared' => sub {
	my ( $ui, $popup ) = popup_ui( is_known => 0 );
	$ui->step;
	is $ui->bounding_box($popup), { x => 7, y => 3, width => 4, height => 2 }, 'attached to its parent with its offset';
	is $ui->step, 0, 'and it asks for no frames';
};

done_testing;
