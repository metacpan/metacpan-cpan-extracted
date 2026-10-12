use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use InputTest;
use Term::Fabulous::Event::MouseMove;
use Term::Fabulous::Layout;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_WHEEL_UP TB_KEY_MOUSE_WHEEL_DOWN TB_MOD_SHIFT);
use Term::Fabulous::Widget::StarRating;

sub rating (%args) {
	my $rating = Term::Fabulous::Widget::StarRating->new(%args);
	my $ui     = layout_ui($rating);
	my @changes;
	$rating->on( Change => sub { push @changes, $_[0]->value; return } );
	return ( $rating, $ui, \@changes );
}

subtest 'painting' => sub {
	my ( $rating, $ui ) = rating( value => 3, show_value => 1 );
	is [ $rating->columns, row_text( $rating, 0 ) ], [ 13, "\x{2605} \x{2605} \x{2605} \x{2606} \x{2606} 3/5" ], 'stars with gaps and the value';
	is shown($rating)->cell( 0, 0 )->[1],            $rating->color_attr( $rating->accent_color ),               'a filled star has the accent color';
	is shown($rating)->cell( 6, 0 )->[1],            $rating->color_attr( $rating->inactive_color ),             'an empty star the inactive color';
	is $rating->accent_color,                        [ 229, 192, 123, 255 ],                                     'the accent defaults to yellow';

	$rating->show_value(0);
	$rating->gap(0);
	is [ row_text( $rating, 0 ), $rating->columns ], [ "\x{2605}\x{2605}\x{2605}\x{2606}\x{2606}", 5 ], 'no gaps, no label';

	my ( $half, $half_ui ) = rating( value => 3.5, half => 1, show_value => 1, half_color => '#ff0000' );
	is row_text( $half, 0 ),            "\x{2605} \x{2605} \x{2605} \x{2605} \x{2606} 3.5/5", 'a half star is drawn with the full glyph';
	is shown($half)->cell( 6, 0 )->[1], $half->color_attr('#ff0000'),                         'in the half color';
	$half->half_glyph("\x{2BEA}");
	like row_text( $half, 0 ), qr/\x{2605} \x{2BEA} \x{2606}/, 'or with a half glyph';

	my ( $ten, $ten_ui ) = rating( max => 10, value => 10, value_format => '%d of 10', show_value => 1 );
	is row_text( $ten, 0 ), ( "\x{2605} " x 9 ) . "\x{2605} 10 of 10", 'ten stars and a sprintf format';
};

subtest 'keys' => sub {
	my ( $rating, $ui, $changes ) = rating( value => 2 );
	press( $rating, $_ ) foreach qw(Right Up Left Down End Right Home Left 4 9);
	is $changes, [ 3, 4, 3, 2, 5, 0, 4 ], 'steps, the ends and digits; no event without a move';
	my ( $half, $half_ui ) = rating( value => 2, half => 1 );
	press( $half, 'Right' );
	is $half->value, 2.5, 'half stars step by a half';
	$half->read_only(1);
	press( $half, 'Right' );
	is [ $half->value, $half->can_focus ], [ 2.5, 0 ], 'a read-only rating ignores keys and takes no focus';
	$half->read_only(0);
	is $half->can_focus, 1, 'and takes it again';
};

subtest 'mouse' => sub {
	my ( $rating, $ui, $changes ) = rating( half => 1 );
	click( $rating, 4, 0 );
	click( $rating, 6, 0, modifiers => TB_MOD_SHIFT );
	click( $rating, 1, 0 );
	click( $rating, 0, 0, key => TB_KEY_MOUSE_WHEEL_UP );
	is $changes, [ 3, 3.5, 4 ], 'a click sets the star, Shift+click a half less, a gap does nothing, the wheel steps';

	$rating->value(5);
	ok !click( $rating, 0, 0, key => TB_KEY_MOUSE_WHEEL_UP )->wheel_used,   'a notch past the end is left to a scroll box';
	ok click( $rating,  0, 0, key => TB_KEY_MOUSE_WHEEL_DOWN )->wheel_used, 'a notch that moves the value is used';

	$rating->value(1);
	my ( $x, $y ) = $rating->content_origin;
	$rating->fire_event( Term::Fabulous::Event::MouseMove->new( x => $x + 6, y => $y ) );
	is row_text( $rating, 0 ), "\x{2605} \x{2605} \x{2605} \x{2605} \x{2606}", 'hovering a star previews the stars up to it';
	is $rating->value,         1,                                              'without changing the value';
	$rating->fire_event( Clay::UI::Events::OnHoverStopped->new );
	is row_text( $rating, 0 ), "\x{2605} \x{2606} \x{2606} \x{2606} \x{2606}", 'the preview goes with the pointer';
};

subtest 'values and layouts' => sub {
	my ( $rating, $ui ) = rating( value => 2.4 );
	is $rating->value, 2, 'a value is rounded to whole stars';
	$rating->max(2);
	is $rating->value, 2, 'and moves into a smaller range';
	like dies { $rating->value(3) }, qr/value must be in 0\.\.2/, 'a value outside the range dies';
	like dies { Term::Fabulous::Widget::StarRating->new( max        => 0 ) },    qr/max must be a positive integer/,        'no stars';
	like dies { Term::Fabulous::Widget::StarRating->new( full_glyph => 'ab' ) }, qr/full_glyph must be a single character/, 'a glyph of two characters';

	my $built = Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::StarRating as StarRating\nStarRating { value 7.5; half #true; max 10; show_value #true; }" )->build;
	is [ $built->max, $built->half, $built->value, $built->show_value ], [ 10, 1, 7.5, 1 ], 'KDL applies max and half before the value';
};

done_testing;
