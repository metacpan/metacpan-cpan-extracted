use v5.32;
use warnings;

use Test2::V0;

use Object::Pad 0.825;

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM CLAY_BACK_TO_FRONT CLAY_RENDER_COMMAND_TYPE_RECTANGLE);
use Scalar::Util qw(refaddr);
use Term::Fabulous::Termbox qw(
	TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_MIDDLE TB_KEY_MOUSE_RIGHT TB_KEY_MOUSE_RELEASE TB_KEY_MOUSE_WHEEL_UP TB_KEY_MOUSE_WHEEL_DOWN TB_KEY_BACK_TAB TB_KEY_ARROW_LEFT
	TB_KEY_ENTER TB_KEY_TAB TB_KEY_CTRL_C TB_KEY_CTRL_W
	TF_KEY_MOUSE_MOVE TF_KEY_MOUSE_WHEEL_RIGHT TF_KEY_F13 TF_KEY_KP_LEFT TF_KEY_KP_7 TF_KEY_KP_BEGIN
	TB_MOD_ALT TB_MOD_CTRL TB_MOD_SHIFT TB_MOD_MOTION TF_MOD_SUPER TF_MOD_HYPER TF_MOD_META
);
use Clay::UI::Revision qw(current_revision);
use Term::Fabulous;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Event::KeyPress;
use Term::Fabulous::Event::Mouse;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Canvas;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::TextArea;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Clay::UI::Text;

# A Clay::UI text node that fires no events (a Term::Fabulous text does,
# since it can take the focus).
class Test::PlainTextNode :does(Clay::UI::Text) { }

# A Term::Fabulous on a 20x5 memory terminal, and the terminal.
sub memory_ui {
	my (%params) = @_;
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 5 );
	return ( Term::Fabulous->new( width => 20, height => 5, terminal => $terminal, %params ), $terminal );
}

# Queues a mouse event and lets the UI handle it and draw.
sub mouse {
	my ( $target_ui, %fields ) = @_;
	$target_ui->terminal->mouse(%fields);
	$target_ui->step;
	return;
}

my $root = Term::Fabulous::Widget::Box->new(
	background_color => [ 1, 1, 1, 255 ],
	layout           => { sizing => { width => sizing_grow(), height => sizing_grow() } },
);
my $button = Term::Fabulous::Widget::Button->new(
	background_color => [ 2, 2, 2, 255 ],
	layout           => { sizing => { width => sizing_fixed(4), height => sizing_fixed(2) } },
);
$root->add_child($button);

my ( $ui, $terminal ) = memory_ui( root => $root );

# Handlers on the root see every event through bubbling; record the widget
# each event was fired on.
my %targets;
foreach my $name (qw(KeyPress Mouse MouseMove OnPress OnRelease)) {
	$root->on( $name => sub { push @{ $targets{$name} }, $_[0]->target; return } );
}

subtest 'KeyPress targets the focused widget' => sub {
	%targets = ();
	$terminal->type_text('a');
	$ui->step;
	ref_is $targets{KeyPress}[0], $root, 'nothing focused: the root';

	$ui->interaction->set_focused_widget($button);
	$terminal->type_text('a');
	$ui->step;
	ref_is $targets{KeyPress}[1], $button, 'the focused button';
	$ui->interaction->set_focused_widget(undef);
};

subtest 'Mouse targets the widget under the pointer' => sub {
	%targets = ();
	mouse( $ui, key => TB_KEY_MOUSE_LEFT, x => 1, y => 1 );
	ref_is $targets{Mouse}[0], $button, 'inside the button';
	is $ui->pointer_state, { x => 1, y => 1, down => 1 }, 'left press sets the pointer down';
	ref_is $targets{OnPress}[0], $button, 'the frame hands the pointer to Clay: the button is pressed';

	mouse( $ui, key => TB_KEY_MOUSE_RELEASE, x => 10, y => 3 );
	ref_is $targets{Mouse}[1], $root, 'outside the button: the root';
	is $ui->pointer_state->{down}, 0, 'release clears the pointer';
};

subtest 'a press and a release within one frame both reach Clay' => sub {
	%targets = ();
	$terminal->mouse( key => TB_KEY_MOUSE_LEFT,    x => 1, y => 1 );
	$terminal->mouse( key => TB_KEY_MOUSE_RELEASE, x => 2, y => 1 );
	ok $ui->step >= 2, 'the step draws a frame for the press and one for the release';
	is [ map { refaddr $_ } $targets{OnPress}[0], $targets{OnRelease}[0] ], [ ( refaddr $button ) x 2 ], 'the frames show the press and then the release';
	is $ui->pointer_state, { x => 2, y => 1, down => 0 }, 'and leave the newest report as the pointer';
};

subtest 'presses count their clicks on the clock of the UI' => sub {
	my $now = 1000;
	my $box = Term::Fabulous::Widget::Box->new( background_color => [ 1, 1, 1, 255 ], layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my ( $clocked, $clocked_terminal ) = memory_ui( root => $box, clock => sub { $now } );
	my @counts;
	$box->on( Mouse => sub { push @counts, $_[0]->click_count; return } );
	my $press = sub { mouse( $clocked, key => TB_KEY_MOUSE_LEFT, x => 1, y => 1, @_ ); return };

	$press->() foreach 1 .. 3;
	is [ splice @counts ], [ 1, 2, 3 ], 'quick presses in one cell count 1, 2, 3';
	$now += 0.4;
	$press->();
	is [ splice @counts ], [4], 'a press double_click_seconds after the one before continues the run';
	$now += 0.41;
	$press->();
	is [ splice @counts ], [1], 'a slower one starts a new run';
	$press->( x => 2 );
	is [ splice @counts ], [1], 'so does a press in another cell';
	$press->( x => 2, key => TB_KEY_MOUSE_RIGHT );
	is [ splice @counts ], [1], 'and a press of another button';
	mouse( $clocked, key => TB_KEY_MOUSE_RELEASE, x => 2, y => 1 );
	$press->( x => 2, key => TB_KEY_MOUSE_RIGHT, mod => TB_MOD_MOTION );
	mouse( $clocked, key => TB_KEY_MOUSE_WHEEL_UP, x => 2, y => 1 );
	is [ splice @counts ], [ 1, 1, 1 ], 'releases, drags and wheel notches count 1';
	$press->( x => 2, key => TB_KEY_MOUSE_RIGHT );
	is [ splice @counts ], [2], 'and do not end a run';

	my ($slow) = memory_ui( root => Term::Fabulous::Widget::Box->new, double_click_seconds => 1.5 );
	is $slow->double_click_seconds, 1.5, 'double_click_seconds is a parameter';
	is $ui->double_click_seconds,   0.4, 'with a default of 0.4 seconds';
	like dies { memory_ui( root => Term::Fabulous::Widget::Box->new, double_click_seconds => -1 ) }, qr/\ATerm::Fabulous: double_click_seconds must be a number of at least 0, got '-1'/,
		'a negative interval dies';
	like dies { Term::Fabulous::Event::Mouse->new( key => TB_KEY_MOUSE_LEFT, x => 0, y => 0, click_count => 0 ) }, qr/click_count must be a positive integer/, 'a click_count of 0 dies';
};

subtest 'MouseMove follows the pointer without a button' => sub {
	%targets = ();
	$terminal->mouse( key => TF_KEY_MOUSE_MOVE, x => 1, y => 1, mod => TB_MOD_MOTION );
	ok $ui->step, 'a frame shows the new position to Clay';
	ref_is $targets{MouseMove}[0], $button, 'MouseMove goes to the widget under the pointer';
	is $targets{Mouse}, undef, 'and is no Mouse event';
	is $ui->pointer_state, { x => 1, y => 1, down => 0 }, 'the pointer position follows the move';
	ok $button->is_hovered, 'so the widget is hovered';
};

subtest 'pointer motion alone gets at most every other slice of time' => sub {
	my ( $now, @readings ) = (1000);    # readings the clock gives before it says $now again
	my ( $paced_ui, $paced ) = memory_ui( root => Term::Fabulous::Widget::Box->new, clock => sub { @readings ? shift @readings : $now } );
	$paced_ui->step;

	my $slow_frame = sub {
		@readings = @_;
		return $paced_ui->step( paced => 1 );
	};
	$paced_ui->invalidate;
	is $slow_frame->( 1000, 1000.05 ), 1, 'a frame that takes 0.05 s';

	$paced->mouse( key => TF_KEY_MOUSE_MOVE, x => 5, y => 3, mod => TB_MOD_MOTION );
	$now = 1000.075;
	is $paced_ui->step( paced => 1 ), 0, 'a move waits while less time passed than the last frame took';
	$now = 1000.1;
	is $slow_frame->( 1000.1, 1000.15 ), 1, 'and is drawn after that';

	$now = 1000.16;
	$paced->mouse( key => TB_KEY_MOUSE_LEFT, x => 5, y => 3 );
	is $slow_frame->( 1000.16, 1000.21 ), 1, 'a press does not wait';
	$now = 1000.22;
	$paced->mouse( key => TB_KEY_MOUSE_RELEASE, x => 5, y => 3 );
	is $paced_ui->step( paced => 1 ), 1, 'nor does a release';

	$paced->mouse( key => TF_KEY_MOUSE_MOVE, x => 6, y => 3, mod => TB_MOD_MOTION );
	is $paced_ui->step, 1, 'without paced, step draws a move at once';
	like dies { $paced_ui->step( pace => 1 ) }, qr/step does not accept pace \(known options: paced\)/, 'unknown step options die';
};

subtest 'frames are drawn only when something changed' => sub {
	$ui->step;
	is $ui->step, 0, 'nothing changed since the last frame';
	$button->background_color( [ 3, 3, 3, 255 ] );
	is $ui->step, 1, 'a widget setter makes a frame due';
	is $ui->step, 0, 'and the frame clears it';
	$terminal->type_text('a');
	is $ui->step, 1, 'input makes a frame due';
	ref_is $ui->invalidate, $ui, 'invalidate returns the UI';
	is $ui->step, 1, 'and makes a frame due';
	my $revision = current_revision();
	$ui->invalidate->step;
	is current_revision(), $revision, 'drawing an unchanged tree changes nothing';
};

subtest 'Mouse targets a canvas without a background' => sub {
	my $canvas_root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $canvas      = Term::Fabulous::Widget::Canvas->new( layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(2) } } );
	$canvas_root->add_child($canvas);
	my ($canvas_ui) = memory_ui( root => $canvas_root );
	my @mouse_targets;
	$canvas_root->on( Mouse => sub { push @mouse_targets, $_[0]->target; return } );

	$canvas_ui->step;
	mouse( $canvas_ui, key => TB_KEY_MOUSE_LEFT, x => 3, y => 1 );
	ref_is $mouse_targets[0], $canvas, 'the canvas paints its box';
};

subtest 'a left press focuses the widget under the pointer' => sub {
	my $focus_root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my @buttons    = map { Term::Fabulous::Widget::Button->new( background_color => [ $_, $_, $_, 255 ], layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(1) } } ) } 1 .. 2;
	my $inner      = Term::Fabulous::Widget::Box->new( background_color => [ 9, 9, 9, 255 ], layout => { sizing => { width => sizing_fixed(2), height => sizing_fixed(1) } } );
	$buttons[1]->add_child($inner);
	$focus_root->add_child(@buttons);
	my ($focus_ui) = memory_ui( root => $focus_root );
	my @focused_at_mouse;
	$focus_root->on( Mouse => sub { push @focused_at_mouse, $focus_ui->interaction->get_focused_widget; return } );
	$focus_ui->step;

	mouse( $focus_ui, key => TB_KEY_MOUSE_LEFT, x => 1, y => 0 );
	ref_is $focused_at_mouse[0], $buttons[0], 'the button is focused before the Mouse event';
	mouse( $focus_ui, key => TB_KEY_MOUSE_LEFT, x => 0, y => 1 );
	ref_is $focus_ui->interaction->get_focused_widget, $buttons[1], 'a press on a child focuses its focusable ancestor';
	mouse( $focus_ui, key => TB_KEY_MOUSE_LEFT, x => 1, y => 0, mod => TB_MOD_MOTION );
	ref_is $focus_ui->interaction->get_focused_widget, $buttons[1], 'dragging does not move the focus';
	mouse( $focus_ui, key => TB_KEY_MOUSE_LEFT, x => 10, y => 3 );
	is $focus_ui->interaction->get_focused_widget, undef, 'a press on nothing focusable blurs';

	my @pressed;
	$_->on( OnPress => sub { push @pressed, $_[0]->target; return } ) foreach @buttons;
	mouse( $focus_ui, key => TB_KEY_MOUSE_RELEASE, x => 1, y => 1 );
	mouse( $focus_ui, key => TB_KEY_MOUSE_LEFT,    x => 3, y => 1 );
	is [ map { refaddr $_ } @pressed ], [ refaddr $buttons[1] ], 'Clay hit-tests the cell, not the edge it shares with the widget above';
};

subtest 'a click where stacked buttons overlap goes to the one on top' => sub {
	my $stack = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_BACK_TO_FRONT } );
	my @buttons
		= map { Term::Fabulous::Widget::Button->new( background_color => [ $_, $_, $_, 255 ], layout => { sizing => { width => sizing_fixed( 6 - 2 * $_ ), height => sizing_fixed(1) } } ) } 1 .. 2;
	$stack->add_child(@buttons);
	my ($stack_ui) = memory_ui( root => $stack );
	my ( @pressed, @mouse_targets );
	$_->on( OnPress => sub { push @pressed, $_[0]->target; return } ) foreach @buttons;
	$stack->on( Mouse => sub { push @mouse_targets, $_[0]->target; return } );
	$stack_ui->step;

	mouse( $stack_ui, key => TB_KEY_MOUSE_LEFT, x => 0, y => 0 );
	ref_is $mouse_targets[0],                          $buttons[1], 'Mouse goes to the later child, drawn on top';
	ref_is $stack_ui->interaction->get_focused_widget, $buttons[1], 'the press focuses it';
	is [ map { refaddr $_ } @pressed ], [ refaddr $buttons[1] ], 'and only it is pressed';

	mouse( $stack_ui, key => TB_KEY_MOUSE_RELEASE, x => 0, y => 0 );
	mouse( $stack_ui, key => TB_KEY_MOUSE_LEFT,    x => 3, y => 0 );
	is [ map { refaddr $_ } @pressed[ 1 .. $#pressed ] ], [ refaddr $buttons[0] ], 'the uncovered part of the lower button is still pressable';
};

subtest 'a click where a removed widget was goes to what is left' => sub {
	my $removal_root = Term::Fabulous::Widget::Box->new( background_color => [ 1, 1, 1, 255 ], layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $doomed       = Term::Fabulous::Widget::Button->new( background_color => [ 2, 2, 2, 255 ], layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(2) } } );
	$removal_root->add_child($doomed);
	my ( $removal_ui, $removal_terminal ) = memory_ui( root => $removal_root );
	my @mouse_targets;
	$removal_root->on( Mouse => sub { push @mouse_targets, $_[0]->target; return } );
	$removal_ui->step;

	$removal_root->clear_children;    # after the frame that still shows the button
	$removal_terminal->mouse( key => TB_KEY_MOUSE_LEFT, x => 1, y => 1 );
	ok lives { $removal_ui->step }, 'the click does not die';
	ref_is $mouse_targets[0], $removal_root, 'the Mouse event goes to the widget below it';
	is $removal_ui->interaction->get_focused_widget, undef, 'and nothing is focused';
};

subtest 'only a release of the left button ends a press' => sub {
	my ($press_ui) = memory_ui( root => Term::Fabulous::Widget::Box->new );
	mouse( $press_ui, key => TB_KEY_MOUSE_LEFT, x => 1, y => 1 );
	mouse( $press_ui, key => TB_KEY_MOUSE_RELEASE, ch => TB_KEY_MOUSE_RIGHT, x => 2, y => 1 );
	is $press_ui->pointer_state->{down}, 1, 'a right release keeps the left button down';
	mouse( $press_ui, key => TB_KEY_MOUSE_RELEASE, ch => TB_KEY_MOUSE_LEFT, x => 2, y => 1 );
	is $press_ui->pointer_state->{down}, 0, 'a left release ends it';
	mouse( $press_ui, key => TB_KEY_MOUSE_LEFT,    x => 1, y => 1 );
	mouse( $press_ui, key => TB_KEY_MOUSE_RELEASE, x => 2, y => 1 );
	is $press_ui->pointer_state->{down}, 0, 'so does a release that names no button';

	my @released;
	$press_ui->root->on( Mouse => sub { push @released, $_[0]->released_button; return } );
	mouse( $press_ui, key => TB_KEY_MOUSE_RELEASE, ch => TB_KEY_MOUSE_MIDDLE, x => 2, y => 1 );
	mouse( $press_ui, key => TB_KEY_MOUSE_LEFT, x => 2, y => 1 );
	is \@released, [ TB_KEY_MOUSE_MIDDLE, undef ], 'the Mouse event names the released button, and only for a release';
	like dies { Term::Fabulous::Event::Mouse->new( key => TB_KEY_MOUSE_LEFT, x => 0, y => 0, released_button => TB_KEY_MOUSE_LEFT ) },
		qr/released_button needs the key TB_KEY_MOUSE_RELEASE/, 'released_button belongs to a release';
	like dies { Term::Fabulous::Event::Mouse->new( key => TB_KEY_MOUSE_RELEASE, x => 0, y => 0, released_button => 42 ) },
		qr/released_button must be TB_KEY_MOUSE_LEFT/, 'and names a button';
};

subtest 'key names' => sub {
	my $name = sub { Term::Fabulous::Event::KeyPress->new( key => $_[0], char => $_[1], modifiers => $_[2] // 0 ) };
	is $name->( 0, ord 'a' )->key_name,                                          'a',               'a character';
	is [ $name->( 0, ord 'a' )->text, $name->( 0, ord 'a', TB_MOD_ALT )->text ], [ 'a', undef ],    'text without Ctrl or Alt only';
	is $name->( TB_KEY_ARROW_LEFT, 0, TB_MOD_CTRL | TB_MOD_SHIFT )->key_name,    'Ctrl+Shift+Left', 'modifiers in a fixed order';
	is $name->( 0x17, 0 )->key_name,                                             'Ctrl+W',          'a control byte is Ctrl and a letter';
	is [ map { $name->( $_, 0, TB_MOD_CTRL )->key_name } 0x7F, 0x0D, 0x1B, 0x09 ], [qw(Backspace Enter Escape Tab)],
		'named control keys, without the Ctrl bit termbox2 sets on them';
	is [ $name->( 0x20, 0 )->key_name, $name->( 0, 0x20 )->key_name, $name->( 0x20, 0 )->text ], [ 'Space', 'Space', ' ' ], 'Space either way';
	is [ $name->( 0, 0x85 )->key_name, $name->( 0, 0x85 )->text ], [ undef, undef ], 'a C1 control character has neither a name nor a text';
};

subtest 'key names of the kitty keyboard protocol' => sub {
	my $name = sub { Term::Fabulous::Event::KeyPress->new( key => $_[0], char => $_[1], modifiers => $_[2] // 0 ) };
	is [ map { $_->key_name } $name->( 0, ord 'i', TB_MOD_CTRL ), $name->( 0, ord '1', TB_MOD_CTRL | TB_MOD_SHIFT ) ], [ 'Ctrl+I', 'Ctrl+Shift+1' ],
		'a Ctrl combination in char is named in upper case';
	is $name->( 0,    0x0D, TB_MOD_CTRL )->key_name,                'Ctrl+Enter',   'a named control key in char takes the Ctrl bit as it is';
	is $name->( 0x17, 0,    TB_MOD_CTRL | TB_MOD_SHIFT )->key_name, 'Ctrl+Shift+W', 'Shift with a control byte';
	is $name->( TB_KEY_ARROW_LEFT, 0, TB_MOD_CTRL | TB_MOD_SHIFT | TF_MOD_SUPER | TF_MOD_HYPER | TF_MOD_META )->key_name, 'Ctrl+Shift+Super+Hyper+Meta+Left',
		'Super, Hyper and Meta after Shift';
	is [ $name->( 0, ord 'a', TF_MOD_SUPER )->key_name, $name->( 0, ord 'a', TF_MOD_SUPER )->text ], [ 'Super+a', undef ], 'Super types nothing';
	is $name->( TF_KEY_F13, 0 )->key_name,                                                           'F13',                'keys without a legacy encoding';
	is [ map { [ $_->key_name, $_->main_key_name ] } $name->( TF_KEY_KP_LEFT, 0, TB_MOD_CTRL ), $name->( TF_KEY_KP_7, 0, TB_MOD_ALT ), $name->( TF_KEY_KP_BEGIN, 0 ) ],
		[ [ 'Ctrl+KeypadLeft', 'Ctrl+Left' ], [ 'Alt+Keypad7', 'Alt+7' ], [ 'KeypadBegin', 'KeypadBegin' ] ],
		'main_key_name names the keypad keys after the main keyboard keys';
};

subtest 'key names back to termbox events' => sub {
	my $fields = sub { my %fields = Term::Fabulous::Event::KeyPress->fields_for_name( $_[0] ); [ @fields{qw(key ch mod)} ] };
	is [ map { $fields->($_) } 'a', 'Ctrl+W', 'Ctrl+I', 'Enter', 'Ctrl+Enter', 'Tab', 'Ctrl+C' ], [
		[ 0,             ord 'a',      0 ],
		[ TB_KEY_CTRL_W, 0,            TB_MOD_CTRL ],    # a control byte
		[ 0,             ord 'i',      TB_MOD_CTRL ],    # the control byte would be Tab
		[ TB_KEY_ENTER,  0,            TB_MOD_CTRL ],    # termbox2 sets Ctrl on every control byte
		[ 0,             TB_KEY_ENTER, TB_MOD_CTRL ],
		[ TB_KEY_TAB,    0,            TB_MOD_CTRL ],
		[ TB_KEY_CTRL_C, 0,            TB_MOD_CTRL ],
		],
		'what termbox2 reports for them';
	my @names = ( 'a', 'A', 'Space', 'Ctrl+Space', 'Alt+x', 'Shift+Enter', 'Ctrl+Shift+W', 'BackTab', 'Ctrl+Shift+Super+Hyper+Meta+Left', 'F13', 'KeypadLeft', 'Ctrl++', "\x{E9}" );
	is [
		map { my %fields = Term::Fabulous::Event::KeyPress->fields_for_name($_); Term::Fabulous::Event::KeyPress->new( key => $fields{key}, char => $fields{ch}, modifiers => $fields{mod} )->key_name }
			@names
		],
		\@names, 'every name comes back as it went in';
	like dies { Term::Fabulous::Event::KeyPress->fields_for_name('Ctrl+w') },     qr/no key is named 'Ctrl\+w'/,    'a name key_name never returns dies';
	like dies { Term::Fabulous::Event::KeyPress->fields_for_name('Hyperspace') }, qr/no key is named 'Hyperspace'/, 'so does an unknown key';
};

subtest 'Tab and Shift-Tab move focus' => sub {
	my $focus_root = Term::Fabulous::Widget::Box->new;
	my @buttons    = map { Term::Fabulous::Widget::Button->new } 1 .. 2;
	$focus_root->add_child($_) foreach @buttons;
	my ( $focus_ui, $focus_terminal ) = memory_ui( root => $focus_root );
	my @key_targets;
	$focus_root->on( KeyPress => sub { push @key_targets, $_[0]->target; return } );
	my $press = sub { $focus_terminal->press_key( $_[0] ); $focus_ui->step; return };

	$press->('Tab');
	ref_is $key_targets[0],                            $focus_root, 'the KeyPress goes to the widget focused before the move';
	ref_is $focus_ui->interaction->get_focused_widget, $buttons[0], 'Tab focuses the first button';

	$press->('Tab');
	ref_is $focus_ui->interaction->get_focused_widget, $buttons[1], 'Tab moves to the next button';

	$press->('BackTab');
	ref_is $focus_ui->interaction->get_focused_widget, $buttons[0], 'Shift-Tab moves back';
	is scalar @key_targets, 3, 'every Tab still fires a KeyPress';
};

class Test::TabKeeper :isa(Term::Fabulous::Widget::Button) {
	field @keys :reader;
	method captures_tab () { return 1 }

	ADJUST {
		$self->on( KeyPress => sub { push @keys, $_[0]->key_name; return } );
	}
}

subtest 'a widget whose captures_tab is true keeps Tab and Shift-Tab' => sub {
	my $focus_root = Term::Fabulous::Widget::Box->new;
	my $keeper     = Test::TabKeeper->new;
	my $other      = Term::Fabulous::Widget::Button->new;
	$focus_root->add_child( $keeper, $other );
	my ( $focus_ui, $focus_terminal ) = memory_ui( root => $focus_root );
	$focus_ui->interaction->set_focused_widget($keeper);
	$focus_terminal->press_key($_) foreach 'Tab', 'BackTab';
	$focus_ui->step;
	ref_is $focus_ui->interaction->get_focused_widget, $keeper, 'the focus stays';
	is [ $keeper->keys ], [ 'Tab', 'BackTab' ], 'and the widget gets both keys';

	$focus_ui->interaction->set_focused_widget($other);
	$focus_terminal->press_key('Tab');
	$focus_ui->step;
	ref_is $focus_ui->interaction->get_focused_widget, $keeper, 'other widgets move the focus as before';
};

subtest 'scroll boxes' => sub {
	my $scroll_root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $header      = Term::Fabulous::Widget::Box->new( background_color => [ 3, 3, 3, 255 ], layout => { sizing => { width => sizing_fixed(6), height => sizing_fixed(2) } } );
	my $log         = Term::Fabulous::Widget::ScrollBox->new(
		id     => 'log',
		layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(6), height => sizing_fixed(3) } },
	);
	my @rows = map { Term::Fabulous::Widget::Box->new( background_color => [ $_, $_, $_, 255 ], layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } } ) } 10 .. 19;
	$log->add_child($_) foreach @rows;
	$scroll_root->add_child($_) foreach $header, $log;
	my ($scroll_ui) = memory_ui( root => $scroll_root );
	my @mouse_targets;
	$scroll_root->on( Mouse => sub { push @mouse_targets, $_[0]->target; return Clay::UI::Enum::Result->CONTINUE } );

	my $row_top = sub {
		my ($row)     = @_;
		my ($command) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE && refaddr( $scroll_ui->widget_for( $_->{userData} ) // 0 ) == refaddr($row) } $scroll_ui->last_frame->commands;
		return $command->{boundingBox}{y};
	};

	$scroll_ui->step;
	is $row_top->( $rows[0] ), 2, 'the first row starts at the top of the box';

	mouse( $scroll_ui, key => TF_KEY_MOUSE_MOVE, x => 1, y => 3, mod => TB_MOD_MOTION );
	$scroll_ui->draw( scroll_cells => [ 0, -3 ] );
	is $row_top->( $rows[3] ), 2, 'scroll_cells scrolls the box under the pointer by whole rows';

	mouse( $scroll_ui, key => TB_KEY_MOUSE_WHEEL_DOWN, x => 1, y => 3 );
	is $row_top->( $rows[3] ), -1, 'a frame applies the wheel notches reported since the last one';

	my $stop_bubbling = 1;
	$log->on( Mouse => sub { return $stop_bubbling ? () : Clay::UI::Enum::Result->CONTINUE } );
	mouse( $scroll_ui, key => TB_KEY_MOUSE_WHEEL_UP, x => 1, y => 3 );
	is $row_top->( $rows[3] ), 2, 'a listener that stops the bubbling does not stop the scrolling';
	$stop_bubbling = 0;
	mouse( $scroll_ui, key => TB_KEY_MOUSE_WHEEL_DOWN, x => 1, y => 3 );

	$log->on( Mouse => sub { $_[0]->use_wheel; return Clay::UI::Enum::Result->CONTINUE } );
	mouse( $scroll_ui, key => TB_KEY_MOUSE_WHEEL_DOWN, x => 1, y => 3 );
	is $row_top->( $rows[3] ), -1, 'a notch a widget used scrolls no scroll box';

	mouse( $scroll_ui, key => TB_KEY_MOUSE_LEFT, x => 1, y => 1 );
	ref_is $mouse_targets[-1], $header, 'content scrolled out of the box does not take the pointer';

	my $sideways = Term::Fabulous::Widget::ScrollBox->new(
		id         => 'sideways',
		horizontal => 1,
		vertical   => 0,
		layout     => { sizing => { width => sizing_fixed(6), height => sizing_fixed(1) } },
	);
	my @columns = map { Term::Fabulous::Widget::Box->new( background_color => [ $_, $_, $_, 255 ], layout => { sizing => { width => sizing_fixed(2), height => sizing_fixed(1) } } ) } 20 .. 29;
	$sideways->add_child(@columns);
	my $sideways_root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$sideways_root->add_child($sideways);
	my ($sideways_ui) = memory_ui( root => $sideways_root );
	$sideways_ui->step;
	mouse( $sideways_ui, key => TF_KEY_MOUSE_WHEEL_RIGHT, x => 1, y => 0 );
	my ($first)
		= grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE && refaddr( $sideways_ui->widget_for( $_->{userData} ) // 0 ) == refaddr( $columns[1] ) } $sideways_ui->last_frame->commands;
	is $first->{boundingBox}{x}, -1, 'a horizontal wheel notch scrolls the box under the pointer by three columns';

	like dies { $scroll_ui->draw( scroll_cells => 3 ) },        qr/scroll_cells must be \[columns, rows\]/, 'scroll_cells must be a pair';
	like dies { $scroll_ui->draw( scroll       => [ 0, 1 ] ) }, qr/unknown argument\(s\): scroll/,          'unknown draw arguments die';
};

subtest 'a text area in a scroll box passes on the notches it cannot use' => sub {
	my $box  = Term::Fabulous::Widget::ScrollBox->new( id => 'form', layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(12), height => sizing_fixed(4) } } );
	my $area = Term::Fabulous::Widget::TextArea->new( value => join( "\n", 1 .. 6 ), layout => { sizing => { width => sizing_fixed(12), height => sizing_fixed(3) } } );
	my $rest = Term::Fabulous::Widget::Box->new( background_color => [ 5, 5, 5, 255 ], layout => { sizing => { width => sizing_grow(), height => sizing_fixed(6) } } );
	$box->add_child( $area, $rest );
	my $form_root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$form_root->add_child($box);
	my ($form_ui) = memory_ui( root => $form_root );
	my $rest_top = sub {
		my ($command) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE && refaddr( $form_ui->widget_for( $_->{userData} ) // 0 ) == refaddr($rest) } $form_ui->last_frame->commands;
		return $command->{boundingBox}{y};
	};
	$form_ui->step;
	is [ $area->top_row, $rest_top->() ], [ 3, 3 ], 'the text area shows its last rows at the top of the box';

	mouse( $form_ui, key => TB_KEY_MOUSE_WHEEL_UP, x => 1, y => 1 );
	is [ $area->top_row, $rest_top->() ], [ 0, 3 ], 'a notch the text area can use scrolls the text area only';

	mouse( $form_ui, key => TB_KEY_MOUSE_WHEEL_DOWN, x => 1, y => 1 );
	is [ $area->top_row, $rest_top->() ], [ 3, 3 ], 'down to its end';
	mouse( $form_ui, key => TB_KEY_MOUSE_WHEEL_DOWN, x => 1, y => 1 );
	is [ $area->top_row, $rest_top->() ], [ 3, 0 ], 'a notch past its end scrolls the box';
};

subtest 'a click within one frame toggles a check box' => sub {
	my $box      = Term::Fabulous::Widget::Checkbox->new( label => 'Fast' );
	my $tap_root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$tap_root->add_child($box);
	my ( $tap_ui, $tap_terminal ) = memory_ui( root => $tap_root );
	$tap_ui->step;
	$tap_terminal->click( 1, 0 );
	$tap_ui->step;
	is $box->checked, 1, 'press and release reported before the same frame';
};

subtest 'clicks on text fire TextClick, clicks on links LinkActivate' => sub {
	my $text_root = Term::Fabulous::Widget::Box->new(
		background_color => [ 1, 1, 1, 255 ],
		layout           => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(10), height => sizing_grow() } },
	);
	my $plain = Term::Fabulous::Widget::Text->new( text => 'one two three' );    # wraps after 'two'
	my $rich = Term::Fabulous::Widget::Text->new( markup => 'see [link=perl.org]perl[/]' );
	$text_root->add_child( $plain, $rich );
	my ($text_ui) = memory_ui( root => $text_root );
	my ( @mouse_targets, @clicks, @activated );
	$text_root->on( Mouse        => sub { push @mouse_targets, $_[0]->target;                  return } );
	$text_root->on( TextClick    => sub { push @clicks,        $_[0];                          return } );
	$text_root->on( LinkActivate => sub { push @activated,     [ $_[0]->target, $_[0]->link ]; return } );
	$text_ui->step;

	mouse( $text_ui, key => TB_KEY_MOUSE_RIGHT, x => 2, y => 1 );
	ref_is $mouse_targets[0], $text_root, 'Mouse still goes to the box behind the text';
	is scalar @clicks, 1, 'and TextClick bubbles up from the text';
	ref_is $clicks[0]->target, $plain, 'fired on the text';
	is [ map { $clicks[0]->$_ } qw(button offset word word_start word_end) ], [ TB_KEY_MOUSE_RIGHT, 10, 'three', 8, 13 ], 'with the character of the wrapped line and its word';
	is \@activated,                                                           [],                                         'no link there';

	mouse( $text_ui, key => TB_KEY_MOUSE_LEFT, x => 7, y => 1 );
	is scalar @clicks, 1, 'the empty rest of a line is no text';
	mouse( $text_ui, key => TB_KEY_MOUSE_LEFT, x => 5, y => 2 );
	is [ $clicks[-1]->link, $clicks[-1]->link_index ],      [ 'perl.org', 0 ],                 'TextClick names the link under the pointer';
	is [ map { [ refaddr $_->[0], $_->[1] ] } @activated ], [ [ refaddr $rich, 'perl.org' ] ], 'a left click on a link activates it';
	ref_is $text_ui->interaction->get_focused_widget, $rich, 'and focuses the Text';
	is $rich->selected_link, 0, 'which selects the clicked link';

	mouse( $text_ui, key => TF_KEY_MOUSE_MOVE, x => 4, y => 2, mod => TB_MOD_MOTION );
	is $rich->hovered_link, 0, 'the pointer over a link hovers it';
	mouse( $text_ui, key => TF_KEY_MOUSE_MOVE, x => 1, y => 2, mod => TB_MOD_MOTION );
	is $rich->hovered_link, undef, 'and leaving it drops the hover';
};

subtest 'a click on either column of a wide character is on that character' => sub {
	my $wide_root = Term::Fabulous::Widget::Box->new( background_color => [ 1, 1, 1, 255 ], layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $text      = Term::Fabulous::Widget::Text->new( text => "\x{3042}b" );
	$wide_root->add_child($text);
	my ($wide_ui) = memory_ui( root => $wide_root );
	my @offsets;
	$wide_root->on( TextClick => sub { push @offsets, $_[0]->offset; return } );
	$wide_ui->step;
	mouse( $wide_ui, key => TB_KEY_MOUSE_RIGHT, x => $_, y => 0 ) foreach 0 .. 2;
	is \@offsets, [ 0, 0, 1 ], 'both columns of the wide character give its offset, the next column the next character';
};

subtest 'a focused Text moves between its links with the keyboard' => sub {
	my $key_root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $rich     = Term::Fabulous::Widget::Text->new( markup => '[link=a]A[/] [link=b]B[/]' );
	my $next     = Term::Fabulous::Widget::Button->new( layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(1) } } );
	$key_root->add_child( $rich, $next );
	my ( $key_ui,    $key_terminal ) = memory_ui( root => $key_root );
	my ( @activated, @passed );
	$key_root->on( LinkActivate => sub { push @activated, $_[0]->link;          return } );
	$key_root->on( KeyPress     => sub { push @passed,    $_[0]->main_key_name; return } );
	my $press = sub { $key_terminal->press_key( $_[0] ); $key_ui->step; return };
	$key_ui->step;

	$press->('Tab');
	ref_is $key_ui->interaction->get_focused_widget, $rich, 'Tab focuses a Text with links';
	is $rich->selected_link, 0, 'which selects its first link';
	$press->($_) foreach qw(Right Enter Right);
	is \@activated, ['b'],              'Right selects the next link, Enter follows it';
	is \@passed,    [ 'Tab', 'Right' ], 'a key that moves nothing goes on to the ancestors';
	$press->('Tab');
	ref_is $key_ui->interaction->get_focused_widget, $next, 'Tab moves on';
	is $rich->selected_link, undef, 'and losing the focus drops the selection';

	$key_ui->interaction->set_focused_widget($rich);
	$rich->markup('[link=c]C[/]');
	$key_ui->step;
	ref_is $key_ui->interaction->get_focused_widget, $rich, 'new markup with links keeps the focus';
	$rich->markup('no links');
	$key_ui->step;
	isnt $key_ui->interaction->get_focused_widget, $rich, 'markup without links gives it up';
};

subtest 'root must be an event emitter' => sub {
	like dies { Term::Fabulous->new( width => 20, height => 5, root => Test::PlainTextNode->new ) },
		qr/root must consume Clay::UI::Role::Events::Emitter/, 'a root that cannot fire events is rejected';
	ok lives { Term::Fabulous->new( width => 20, height => 5, root => Term::Fabulous::Widget::Text->new ) }, 'a Text can be the root';
	like dies { Term::Fabulous->new( width => 20, height => 5, root => Term::Fabulous::Widget::Box->new, use_termbox => 1 ) },
		qr/Unrecognised parameters.*use_termbox/, 'unknown constructor parameters are rejected';
	like dies { Term::Fabulous->new( width => 20, height => 5, root => Term::Fabulous::Widget::Box->new, terminal => 'tty' ) },
		qr/terminal must consume Term::Fabulous::Role::Terminal, got 'tty'/, 'the terminal must be a terminal';
};

subtest 'a text that gets its first link later handles the keys' => sub {
	my $late_root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $late      = Term::Fabulous::Widget::Text->new( text => 'A B' );
	$late_root->add_child($late);
	my ( $late_ui, $late_terminal ) = memory_ui( root => $late_root );
	$late_ui->step;
	is $late->can_focus, 0, 'without links a text cannot take the focus';
	$late->add_link( 'a', 0, 1 )->add_link( 'b', 2, 3 );
	$late_ui->interaction->set_focused_widget($late);
	is $late->selected_link, 0, 'the focus selects the first link';
	$late_terminal->press_key('Right');
	$late_ui->step;
	is $late->selected_link, 1, 'and Right selects the next one';
};

done_testing;
