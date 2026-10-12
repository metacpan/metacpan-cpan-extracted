use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_fixed);
use InputTest;
use Term::Fabulous::Event::MouseMove;
use Term::Fabulous::Layout;
use Term::Fabulous::Widget::SegmentedControl;

sub control (%args) {
	my $control = Term::Fabulous::Widget::SegmentedControl->new( options => [qw(Day Week Month)], %args );
	my $ui      = layout_ui($control);
	my @changes;
	$control->on( Change => sub { push @changes, $_[0]->value; return } );
	return ( $control, $ui, \@changes );
}

subtest 'painting' => sub {
	my ( $control, $ui ) = control( value => 'Week' );
	is [ $control->columns, $control->rows, row_text( $control, 0 ) ], [ 20, 1, " Day \x{2502} Week \x{2502} Month " ], 'labels with padding and separators';
	is shown($control)->cell( 7, 0 )->[2], $control->color_attr( $control->accent_color ), 'the selected segment sits on the accent color';
	is shown($control)->cell( 1, 0 )->[2], undef,                                          'the others on the widget background';

	my ( $wide, $wide_ui ) = control( value => 'Day', layout => { sizing => { width => sizing_fixed(32) } } );
	is row_text( $wide, 0 ), "   Day   \x{2502}   Week   \x{2502}   Month   ", 'extra width is shared out, labels centered';

	my ( $vertical, $vertical_ui ) = control( vertical => 1, value => 'Day' );
	is [ $vertical->columns, $vertical->rows ], [ 7, 3 ], 'vertical: the widest label, a row per option';
	is [ map { row_text( $vertical, $_ ) } 0 .. 2 ], [ '  Day  ', ' Week  ', ' Month ' ], 'one segment per row, labels centered';

	$control->separator(undef);
	$control->segment_padding(0);
	is row_text( $control, 0 ), 'DayWeekMonth', 'no separators, no padding';
	$control->option_disabled( 2, 1 );
	is shown($control)->cell( 8, 0 )->[1], $control->color_attr( $control->disabled_color ), 'a disabled option is gray';
};

subtest 'keys' => sub {
	my ( $control, $ui, $changes ) = control();
	press( $control, $_ ) foreach qw(Right Right Right Left Home End 2 9 Up);
	is $changes, [ 'Day', 'Week', 'Month', 'Week', 'Day', 'Month', 'Week', 'Day' ], 'steps wrap around, Home, End and digits choose';
	$control->option_disabled( 1, 1 );
	$control->value('Day');
	press( $control, 'Right' );
	press( $control, '2' );
	is $control->value, 'Month', 'a disabled segment is skipped and cannot be chosen';
};

subtest 'mouse' => sub {
	my ( $control, $ui, $changes ) = control( value => 'Day' );
	click( $control, 8,  0 );
	click( $control, 5,  0 );
	click( $control, 16, 0 );
	is $changes, [ 'Week', 'Month' ], 'a click chooses the segment, a separator nothing';

	my ( $x, $y ) = $control->content_origin;
	$control->fire_event( Term::Fabulous::Event::MouseMove->new( x => $x + 1, y => $y ) );
	is shown($control)->cell( 1, 0 )->[2], $control->color_attr( $control->hover_background_color ), 'the segment under the pointer is highlighted';
	$control->fire_event( Clay::UI::Events::OnHoverStopped->new );
	is shown($control)->cell( 1, 0 )->[2], undef, 'until the pointer leaves';
};

subtest 'options, values and layouts' => sub {
	my ( $control, $ui ) = control( options => [ 'List', [ Grid => 'g' ], { label => 'Map', value => 'm', disabled => 1 } ], value => 'g' );
	is [ $control->options ], [ { label => 'List', value => 'List', disabled => 0 }, { label => 'Grid', value => 'g', disabled => 0 }, { label => 'Map', value => 'm', disabled => 1 } ],
		'the three option forms';
	$control->options( [ 'Map', [ Grid => 'g' ] ] );
	is [ $control->value, $control->selected_index ], [ 'g', 1 ], 'new options keep the selected value';
	like dies { $control->value('x') },                                                               qr/no option has the value 'x'/,                'an unknown value dies';
	like dies { $control->choose(5) },                                                                qr/choose needs an option index in 0\.\.1/,     'an index outside the options dies';
	like dies { $control->options( ['a'] ); $control->options( [ {} ] ) },                            qr/an option must be a label/,                  'an option without a label dies';
	like dies { Term::Fabulous::Widget::SegmentedControl->new( value => 'a', selected_index => 0 ) }, qr/give 'value' or 'selected_index', not both/, 'value and index together die';

	my $built = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::SegmentedControl as SegmentedControl
SegmentedControl "period" {
	value "y"
	options "Day" "Week"
	option "Year" value="y" disabled=#true
	vertical #true
	segment_padding 0
}
KDL
	is [ $built->value, $built->vertical, $built->segment_padding, ( $built->options )[2] ], [ 'y', 1, 0, { label => 'Year', value => 'y', disabled => 1 } ], 'KDL adds the options before the value';
};

done_testing;
