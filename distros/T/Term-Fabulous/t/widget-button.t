use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_fixed sizing_grow);
use InputTest;
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RELEASE);
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;

my $root   = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $button = Term::Fabulous::Widget::Button->new(
	background_color => [ 2, 2, 2, 255 ],
	bordered         => 1,
	border_color     => [ 5, 5, 5, 255 ],
	layout           => { sizing => { width => sizing_fixed(6), height => sizing_fixed(3) } },
);
$root->add_child($button);
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 5 );
my $ui       = Term::Fabulous->new( width => 20, height => 5, root => $root, terminal => $terminal );

my @activations;
my @keys_at_root;
$button->on( Activate => sub { push @activations, $_[0]->target; return } );
$root->on( KeyPress => sub { push @keys_at_root, $_[0]->key_name; return } );

subtest 'Enter and Space activate, other keys bubble' => sub {
	press( $button, 'Enter' );
	press( $button, 'Space' );
	press( $button, 'x' );
	is scalar @activations, 2, 'Enter and Space fire Activate';
	ref_is $activations[0], $button, 'on the button';
	is \@keys_at_root, ['x'], 'the used keys do not bubble, the others do';
	$button->activate;
	is scalar @activations, 3, 'activate fires it from code';
};

subtest 'a click activates and shows the pressed look' => sub {
	@activations = ();
	$ui->step;
	$terminal->mouse( key => TB_KEY_MOUSE_LEFT, x => 2, y => 1 );
	$ui->step;
	ok $button->is_pressed,    'the button is pressed after the frame';
	ok $button->reverse_video, 'and drawn in reverse video';

	$terminal->mouse( key => TB_KEY_MOUSE_RELEASE, x => 2, y => 1, ch => TB_KEY_MOUSE_LEFT );
	$ui->step;
	is scalar @activations, 1, 'the release over the button fires Activate';
	ok !$button->reverse_video, 'the pressed look is gone';
};

subtest 'a disabled button' => sub {
	my $label = Term::Fabulous::Widget::Text->new( text => 'Go', text_color => [ 255, 255, 255, 255 ] );
	my $off
		= Term::Fabulous::Widget::Button->new( disabled => 1, bordered => 1, border_color => [ 5, 5, 5, 255 ], layout => { sizing => { width => sizing_fixed(6), height => sizing_fixed(3) } } );
	$off->add_child($label);
	my $off_root = Term::Fabulous::Widget::Box->new;
	$off_root->add_child($off);
	my $off_terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 5 );
	my $off_ui       = Term::Fabulous->new( width => 20, height => 5, root => $off_root, terminal => $off_terminal );
	my @fired;
	$off->on( Activate => sub { push @fired, 'Activate'; return } );
	$off_ui->step;

	$off_terminal->click( 2, 1 );
	$off_ui->step;
	press( $off, 'Enter' );
	press( $off, 'Space' );
	is [ \@fired, $off_ui->interaction->get_focused_widget ], [ [], undef ], 'clicks, Enter and Space do nothing, and it takes no focus';
	is $off_terminal->cell( 0, 0 )->[1], 0x6C7078, 'the border is drawn in disabled_color';
	is $off_terminal->cell( 1, 1 )->[1], 0x6C7078, 'and so is the text inside';
	ok $off->has_state('disabled'), 'it has the disabled state';

	$off->disabled(0);
	$off_terminal->click( 2, 1 );
	$off_ui->step;
	is [ \@fired, $off_terminal->cell( 1, 1 )->[1] ], [ ['Activate'], 0xFFFFFF ], 'enabled again it works and shows its own colors';
	like dies { $off->disabled_color('nope') }, qr/\ATerm::Fabulous::Widget::Button: disabled_color must be a color/, 'disabled_color is checked';
};

subtest 'the pressed look can be a color or nothing' => sub {
	my $colored = Term::Fabulous::Widget::Button->new( background_color => [ 2, 2, 2, 255 ], pressed_background_color => '#ff0000' );
	is $colored->pressed_background_color, [ 255, 0, 0, 255 ], 'a color is stored as rgba';
	is $colored->reverse_video,            0,                  'a colored press is not reverse video';

	my $plain = Term::Fabulous::Widget::Button->new( pressed_background_color => undef );
	is $plain->pressed_background_color,            undef,     'undef switches the pressed look off';
	is $button->pressed_background_color,           'reverse', 'the default is reverse video';
	is $plain->pressed_background_color('reverse'), 'reverse', 'and can be set back';
	like dies { Term::Fabulous::Widget::Button->new( pressed_background_color => 'nope' ) }, qr/\ATerm::Fabulous::Widget::Button: pressed_background_color must be a color, got 'nope'/,
		'an invalid color dies';
};

subtest 'the focused button draws its border in the focus color' => sub {
	$ui->interaction->set_focused_widget(undef);
	my $config = sub { $button->to_config->{border}{color} };
	is $config->(), [ 5, 5, 5, 255 ], 'unfocused: the border color';
	$ui->interaction->set_focused_widget($button);
	is $config->(), [ 97, 175, 239, 255 ], 'focused: the focus border color';

	$button->focus_border_color('#ffffff');
	is $config->(), [ 255, 255, 255, 255 ], 'in any color format';
	$button->focus_border_color(undef);
	is $config->(), [ 5, 5, 5, 255 ], 'undef switches the focus look off';
	like dies { $button->focus_border_color('nope') }, qr/\ATerm::Fabulous::Widget::Button: focus_border_color must be a color, got 'nope'/, 'an invalid color dies';
	$ui->interaction->set_focused_widget(undef);
};

subtest 'KDL properties' => sub {
	my $built = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Button as Button
Button "ok" {
	focus_border_color "#ffffff"
	pressed_background_color "#ff0000"
	can_focus #false
	disabled #true
	disabled_color "#808080"
}
KDL
	is [ $built->focus_border_color, $built->pressed_background_color, $built->can_focus, $built->disabled, $built->disabled_color ],
		[ [ 255, 255, 255, 255 ], [ 255, 0, 0, 255 ], 0, 1, [ 128, 128, 128, 255 ] ], 'all five properties';

	my $plain = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Button as Button
Button "plain" {
	focus_border_color #null
	pressed_background_color "reverse"
}
KDL
	is [ $plain->focus_border_color, $plain->pressed_background_color ], [ undef, 'reverse' ], '#null switches a look off, "reverse" is the reverse look';
	like dies { Term::Fabulous::Layout->new( string => qq{use Term::Fabulous::Widget::Button as Button\nButton { focus_border_color "reverse"; }} )->build },
		qr/Term::Fabulous::Widget::Button: focus_border_color must be a color, got 'reverse'/, 'only the pressed look can be reverse';
};

done_testing;
