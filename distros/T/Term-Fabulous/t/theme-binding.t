use v5.32;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Object::Pad 0.825;

use Clay::XS qw(sizing_fixed);
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Static;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Display;
use Term::Fabulous::Widget::Divider;
use Term::Fabulous::Widget::LineChart;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Tabs;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

my $Theme = 'Term::Fabulous::Theme';
my $dark  = $Theme->default;
my $light = $Theme->builtin('light');

my $red = $Theme->new(
	name     => 'red',
	palette  => { text               => '#ff0000' },
	slots    => { 'box.border.style' => 'Round', 'box.border.color' => '#00ff00', 'box.background' => '#0000ff' },
	variants => { 'text.muted'       => { color => '#808080' }, 'box.panel' => { background => '#111111' } },
);

sub static ( $root, %params ) {
	return Term::Fabulous::Static->new( root => $root, width => 20, %params );
}

subtest 'the theme of a UI' => sub {
	my $ui = static( Term::Fabulous::Widget::Box->new );
	ref_is $ui->theme, $dark, 'the default theme is dark';
	ref_is static( Term::Fabulous::Widget::Box->new, theme => 'light' )->theme, $light, 'a built-in theme by name';
	ref_is static( Term::Fabulous::Widget::Box->new, theme => $red )->theme,    $red,   'a theme object';
	like dies { static( Term::Fabulous::Widget::Box->new, theme => 'neon' ) }, qr/theme must be a Term::Fabulous::Theme or the name of a built-in theme \(dark, light\), got 'neon'/,
		'an unknown name dies';
	like dies { static( Term::Fabulous::Widget::Box->new, theme => {} ) }, qr/got a HASH reference/, 'a hash dies';

	my $generation = Term::Fabulous::Theme::generation();
	ref_is $ui->theme('light'), $light, 'the writer returns the new theme';
	is Term::Fabulous::Theme::generation(), $generation + 1, 'setting a theme bumps the generation';
	like dies { $ui->theme(undef) }, qr/got undef/, 'the writer checks too';
};

subtest 'the screen background' => sub {
	my $transparent = $Theme->new( name => 'transparent', palette => { background => [ 0, 0, 0, 0 ] } );
	my $small_box   = sub { Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(2), height => sizing_fixed(1) } } ) };

	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 4, height => 2 );
	my $ui       = Term::Fabulous->new( root => $small_box->(), width => 4, height => 2, terminal => $terminal );
	$ui->step;
	is $terminal->cell( 3, 1 ), [ ' ', 0, 0x161622 ], 'a cell no widget paints shows the background token of the dark theme';
	is [ $terminal->lines ], [ '    ', '    ' ], 'so no cell of the screen is blank';

	$ui->theme('light');
	$ui->step;
	is $terminal->cell( 3, 1 )->[2], 0xFAFAF7, 'a theme switch repaints the screen in the new background';

	$ui->theme($transparent);
	$ui->step;
	is $terminal->cell( 3, 1 ), undef, 'a background token with alpha 0 leaves the terminal\'s own background';

	is static( $small_box->(), width => 4 )->cell( 3, 0 ), undef, 'Static paints no screen background';
};

subtest 'a widget reads the theme of its UI' => sub {
	my $text = Term::Fabulous::Widget::Text->new( text => 'hello' );
	is $text->text_color,    $dark->token('text'), 'outside a UI, the default theme';
	is $text->look('color'), $dark->token('text'), 'look reads a slot';

	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($text);
	my $ui = static( $root, theme => $red );
	is $text->text_color,                [ 255, 0, 0, 255 ], 'in a UI, that UI\'s theme';
	is $text->text_config->{text_color}, [ 255, 0, 0, 255 ], 'and the text is drawn in it';

	$ui->theme('light');
	is $text->text_color, $light->token('text'), 'a switch shows in the next read';

	my $late = Term::Fabulous::Widget::Text->new( text => 'late' );
	is $late->text_color, $dark->token('text'), 'a widget built later reads the default theme while outside';
	$root->add_child($late);
	is $late->text_color, $light->token('text'), 'and the UI\'s theme once it joined the tree';
	$root->remove_children_with( sub { $_ == $late } );
	is $late->text_color, $dark->token('text'), 'and the default theme again once it left';
};

class Test::PreviewUI :isa(Term::Fabulous::Static) {
	field $preview :param;
	field $preview_theme = 'light';

	method theme_for :override ($widget) {
		return $self->SUPER::theme_for($widget) unless $preview->contains($widget);
		return Term::Fabulous::Theme->builtin($preview_theme);
	}

	method preview_theme ($theme) {
		$preview_theme = $theme;
		$self->refresh_looks;
		return $self;
	}
}

subtest 'a UI subclass gives part of its tree another theme' => sub {
	my $outside = Term::Fabulous::Widget::Text->new( text => 'controls' );
	my $inside  = Term::Fabulous::Widget::Text->new( text => 'preview' );
	my $preview = Term::Fabulous::Widget::Box->new;
	$preview->add_child($inside);
	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child( $outside, $preview );
	my $ui = Test::PreviewUI->new( root => $root, width => 20, preview => $preview );

	ref_is $ui->theme_for($outside), $dark, 'theme_for is the UI\'s theme by default';
	is $outside->text_color, $dark->token('text'),  'a widget outside the preview reads the UI\'s theme';
	is $inside->text_color,  $light->token('text'), 'a widget inside reads what theme_for returns';

	my $generation = Term::Fabulous::Theme::generation();
	ref_is $ui->refresh_looks, $ui, 'refresh_looks returns the UI';
	is Term::Fabulous::Theme::generation(), $generation + 1, 'and bumps the generation';
	$ui->preview_theme('dark');
	is $inside->text_color, $dark->token('text'), 'after refresh_looks the preview reads the new theme';
	$ui->preview_theme('light');
	$ui->theme($red);
	is [ $outside->text_color, $inside->text_color ], [ [ 255, 0, 0, 255 ], $light->token('text') ], 'a theme switch reaches the rest of the tree only';
};

subtest 'explicit values win and reset_look returns to the theme' => sub {
	my $text = Term::Fabulous::Widget::Text->new( text => 'x', text_color => '#123456' );
	is $text->text_color,                [ 18, 52, 86, 255 ], 'an explicit color';
	is $text->text_config->{text_color}, [ 18, 52, 86, 255 ], 'is drawn';
	ok $text->has_look_override('text_color'), 'has_look_override';
	ref_is $text->reset_look('text_color'), $text, 'reset_look returns the widget';
	is $text->text_color, $dark->token('text'), 'the theme again';
	ok !$text->has_look_override('text_color'), 'no override any more';
	$text->text_color( [ 1, 2, 3 ] );
	is $text->text_color, [ 1, 2, 3, 255 ], 'the writer sets an explicit color';
	like dies { $text->text_color(undef) },  qr/text_color must be a color, got undef/,                 'undef is not a color';
	like dies { $text->reset_look('glow') }, qr/reset_look does not know 'glow' \(known: text_color\)/, 'an unknown parameter dies';

	my $box = Term::Fabulous::Widget::Box->new( background_color => '#ff00ff', border_color => '#00ffff', bordered => 1 );
	is $box->to_config->{background_color}, [ 255, 0,   255, 255 ], 'an explicit box background';
	is $box->to_config->{border}{color},    [ 0,   255, 255, 255 ], 'an explicit box border color';
	$box->reset_look( 'background_color', 'border_color' );
	is $box->background_color,               undef, 'the box has no background of its own any more';
	is $box->to_config->{background_color},  undef, 'and the dark theme gives a box none';
	is $box->look_value('background_color'), undef, 'look_value says so';
	like dies { $box->look_value('glow') }, qr/look_value does not know 'glow' \(known: background_color, border_color, bordered\)/, 'look_value checks the name';
};

subtest 'the theme fills what a box left open' => sub {
	my $box = Term::Fabulous::Widget::Box->new( bordered => 1 );
	my $ui  = static( $box, theme => $red );
	is $box->to_config->{background_color},  [ 0, 0,   255, 255 ], 'the background from the theme';
	is $box->to_config->{border}{color},     [ 0, 255, 0,   255 ], 'the border color from the theme';
	is $box->background_color,               [ 0, 0,   255, 255 ], 'the reader returns the color in use';
	is $box->look_value('background_color'), [ 0, 0,   255, 255 ], 'and so does look_value';
	ok !$box->has_look_override('background_color'), 'which is no override';

	$box->background_color('#ffffff');
	is $box->to_config->{background_color}, [ 255, 255, 255, 255 ], 'an explicit background wins';

	my $plain    = Term::Fabulous::Widget::Box->new;
	my $plain_ui = static($plain);
	is $plain->to_config->{background_color}, undef, 'under the dark theme a box stays transparent';
	ok !exists $plain->to_config->{border}, 'and has no border';

	my $framed = Term::Fabulous::Widget::Box->new( bordered => 1, border_color => '#ffffff', layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(2) } } );
	is [ static( $framed, theme => $red )->render_lines( colors => 0 ) ], [ "\x{256D}\x{2500}\x{2500}\x{256E}", "\x{2570}\x{2500}\x{2500}\x{256F}" ], 'the border style from the theme';
	$framed->border_style_top( Term::Fabulous::Enum::BorderStyle->Double );
	is [ static( $framed, theme => $red )->render_lines( colors => 0 ) ], [ "\x{2554}\x{2550}\x{2550}\x{2557}", "\x{2570}\x{2500}\x{2500}\x{256F}" ], 'an explicit side keeps its style';
};

subtest 'border.enabled gives a widget a border unless bordered says otherwise' => sub {
	my $field = Term::Fabulous::Widget::TextField->new;
	my $plain = Term::Fabulous::Widget::TextField->new( bordered => 0 );
	my $root  = Term::Fabulous::Widget::Box->new;
	$root->add_child( $field, $plain );
	my $ui = static( $root, theme => $Theme->new( slots => { 'text_input.border.enabled' => 1 } ) );
	is $field->bordered, { top => 1, right => 1, bottom => 1, left => 1 }, 'the theme gives a text field a border';
	ok !$field->has_look_override('bordered'), 'which is no override';
	is $field->to_config->{border}{width}{top}, 1, 'and Clay draws it';
	ok !exists $plain->to_config->{border}, 'an explicit bordered => 0 wins';
	$plain->reset_look('bordered');
	is $plain->bordered->{top}, 1, 'reset_look returns it to the theme';
	$ui->theme('dark');
	ok !exists $field->to_config->{border}, 'a theme switch takes the border away';

	my $box = Term::Fabulous::Widget::Box->new;
	is $box->bordered, { top => 0, right => 0, bottom => 0, left => 0 }, 'a box has no border.enabled: only the program gives it a border';
};

subtest 'classes select variants' => sub {
	my $text = Term::Fabulous::Widget::Text->new( text => 'x', classes => ['muted'] );
	is $text->classes, ['muted'], 'the classes reader';
	my $ui = static( $text, theme => $red );
	is $text->text_color, [ 128, 128, 128, 255 ], 'the variant of the class';
	$text->classes( [] );
	is $text->text_color, [ 255, 0, 0, 255 ], 'without the class, the family';
	$text->classes( [ 'other', 'muted' ] );
	is $text->text_color, [ 128, 128, 128, 255 ], 'a class without a variant changes nothing';
	like dies { $text->classes('muted') }, qr/classes must be an array reference of names, got 'muted'/, 'the writer checks';

	my $box    = Term::Fabulous::Widget::Box->new( classes => ['panel'] );
	my $box_ui = static( $box, theme => $red );
	is $box->to_config->{background_color}, [ 17, 17, 17, 255 ], 'a box variant';
	is [ $box->get_classes ],               ['panel'],           'get_classes still lists the names';

	my $root = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Box as Box
use Term::Fabulous::Widget::Text as Text
Box "root" {
	classes "panel" "wide"
	Text { text "x"; classes "muted" }
}
KDL
	is $root->classes,                [ 'panel', 'wide' ], 'classes from a layout file';
	is $root->children->[0]->classes, ['muted'],           'on a Text too';
	like dies { Term::Fabulous::Layout->new( string => qq{use Term::Fabulous::Widget::Box as Box\nBox { classes 1 }\n} )->build }, qr/layout property 'classes' takes one or more string arguments/,
		'a number dies';
};

subtest 'text inside a button' => sub {
	my $button = Term::Fabulous::Widget::Button->new;
	my $text   = Term::Fabulous::Widget::Text->new( text => 'Save' );
	my $given  = Term::Fabulous::Widget::Text->new( text => 'Go', text_color => '#123456' );
	$button->add_child( $text, $given );
	my $ui = static($button);
	is $text->text_config->{text_color},  $dark->look( 'button', 'text' ), 'a text without a color takes the button\'s text look';
	is $given->text_config->{text_color}, [ 18, 52, 86, 255 ],             'an explicit color stays';
	$button->disabled(1);
	is $text->text_config->{text_color},  $button->disabled_color, 'a disabled button grays its texts';
	is $given->text_config->{text_color}, $button->disabled_color, 'explicit colors too';
};

subtest 'a button follows its state and its variant' => sub {
	my $theme = $Theme->new(
		slots    => { 'button.border.color' => '#101010', 'button.border.color.hovered' => '#202020', 'button.text.pressed' => '#303030' },
		variants => { 'button.primary'      => { 'border.color' => '#404040', 'border.color.focused' => '#505050' } },
	);
	my $button = Term::Fabulous::Widget::Button->new( bordered => 1 );
	my $label  = Term::Fabulous::Widget::Text->new( text => 'Go' );
	$button->add_child($label);
	my $ui     = static( $button, theme => $theme );
	my $border = sub { $button->to_config->{border}{color} };
	is $border->(),                       [ 16, 16, 16, 255 ],       'the theme colors the border';
	is $button->focus_border_color,       $theme->token('accent'),   'the focus color is the theme\'s';
	is $button->pressed_background_color, 'reverse',                 'and so is the pressed look';
	is $button->disabled_color,           $theme->token('disabled'), 'and the disabled color';
	is $label->text_config->{text_color}, $theme->token('text'),     'the label takes button.text';

	$ui->interaction->set_focused_widget($button);
	is $border->(), $theme->token('accent'), 'focused: the theme\'s focused border';
	$button->focus_border_color('#ffffff');
	is $border->(), [ 255, 255, 255, 255 ], 'an explicit focus color wins';
	$button->reset_look('focus_border_color');
	is $border->(), $theme->token('accent'), 'reset_look returns it to the theme';
	$ui->interaction->set_focused_widget(undef);

	$button->border_color('#0000ff');
	is $border->(), [ 0, 0, 255, 255 ], 'an explicit border color';
	$ui->interaction->set_focused_widget($button);
	is $border->(), $theme->token('accent'), 'the focused look still wins over it';
	$ui->interaction->set_focused_widget(undef);
	$button->reset_look('border_color');

	$button->classes( ['primary'] );
	is $border->(), [ 64, 64, 64, 255 ], 'the variant\'s border';
	$ui->interaction->set_focused_widget($button);
	is $border->(), [ 80, 80, 80, 255 ], 'and its focused border';
	$ui->interaction->set_focused_widget(undef);

	$button->disabled(1);
	is $border->(),                       $theme->token('disabled'), 'disabled wins over everything';
	is $label->text_config->{text_color}, $theme->token('disabled'), 'and grays the label';
	$button->disabled_color('#606060');
	is $label->text_config->{text_color}, [ 96, 96, 96, 255 ], 'a given disabled color grays the label too';
};

subtest 'a theme switch reaches the tabs' => sub {
	require Term::Fabulous::Widget::Tabs;
	require Term::Fabulous::Widget::Tabs::Page;
	my $tabs = Term::Fabulous::Widget::Tabs->new( page_border => 1, layout => { sizing => { width => sizing_fixed(20), height => sizing_fixed(6) } } );
	$tabs->add_child( map { Term::Fabulous::Widget::Tabs::Page->new( title => $_ ) } qw(One Two) );
	my $ui = static( $tabs, theme => $Theme->new( palette => { outline => '#102030', text_dim => '#405060', text => '#708090' }, slots => { 'tabs.line.style' => 'Heavy' } ) );
	$ui->render_lines;
	is $ui->cell( 1,  0 )->[1], 0x102030,   'the tab border takes tabs.line.color';
	is $ui->cell( 1,  0 )->[0], "\x{250F}", 'and tabs.line.style';
	is $ui->cell( 3,  1 )->[1], 0x708090,   'the active label takes tabs.text.active';
	is $ui->cell( 11, 1 )->[1], 0x405060,   'the other label tabs.text';
	is $ui->cell( 0,  4 )->[1], 0x102030,   'the page border takes the line color';

	$ui->theme( $Theme->new( palette => { outline => '#ff0000' } ) );
	$ui->render_lines;
	is $ui->cell( 1, 0 )->[1], 0xFF0000,   'a switch recolors the tabs';
	is $ui->cell( 0, 4 )->[1], 0xFF0000,   'and the page border';
	is $ui->cell( 1, 0 )->[0], "\x{256D}", 'and restyles the line';

	$tabs->line_color('#00ff00');
	$ui->render_lines;
	is $ui->cell( 1, 0 )->[1], 0x00FF00, 'an explicit line color wins';
	is $ui->cell( 0, 4 )->[1], 0x00FF00, 'on the page too';
};

subtest 'a theme switch reaches a table, its pager and its scrollbar' => sub {
	require Term::Fabulous::Widget::Table;
	require Term::Fabulous::Widget::ScrollBox;
	my $table = Term::Fabulous::Widget::Table->new(
		id      => 'themed',
		columns => [ { key => 'name', title => 'Name' } ],
		rows    => [ map { { name => "row $_" } } 1 .. 20 ],
		layout  => { sizing => { width => sizing_fixed(20), height => sizing_fixed(8) } },
	);
	my $ui = static( $table, theme => $Theme->new( palette => { text => '#102030', line => '#405060', text_bright => '#708090' } ) );
	$ui->render_lines;
	is $table->text_color,                [ 16, 32, 48, 255 ], 'the text color is the theme\'s';
	is $table->line_color,                [ 64, 80, 96, 255 ], 'and the line color';
	is $ui->cell( 2, 1 )->[1] & 0xFFFFFF, 0x708090,            'the header is drawn in table.header.text';
	is $ui->cell( 2, 3 )->[1],            0x102030,            'a cell in table.text';
	is $ui->cell( 0, 3 )->[1],            0x405060,            'the lines in table.line.color';

	$ui->theme( $Theme->new( palette => { text => '#ff0000', line => '#00ff00' } ) );
	$ui->render_lines;
	is $ui->cell( 2, 3 )->[1], 0xFF0000, 'a switch recolors the cells';
	is $ui->cell( 0, 3 )->[1], 0x00FF00, 'and the lines';

	$table->text_color('#0000ff');
	$ui->render_lines;
	is $ui->cell( 2, 3 )->[1], 0x0000FF, 'an explicit color wins';
	$table->reset_look('text_color');
	$ui->render_lines;
	is $ui->cell( 2, 3 )->[1], 0xFF0000, 'reset_look returns to the theme';

	my $box = Term::Fabulous::Widget::ScrollBox->new( id => 'scroll', layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(3) } } );
	$box->add_child( Term::Fabulous::Widget::Text->new( text => "a\nb\nc\nd\ne\nf" ) );
	my $scroll_ui = static( $box, theme => $Theme->new( palette => { accent => '#ff00ff', track_scroll => '#00ffff' } ) );
	$scroll_ui->render_lines;
	is $box->thumb_color,             [ 255, 0,   255, 255 ], 'the scrollbar thumb is the theme accent';
	is $box->track_color,             [ 0,   255, 255, 255 ], 'the track scrollbar.track';
	is $scroll_ui->cell( 9, 0 )->[1], 0xFF00FF, 'and painted so';
	$scroll_ui->theme('dark');
	$scroll_ui->render_lines;
	is $scroll_ui->cell( 9, 0 )->[1], 0x61AFEF, 'a switch repaints the scrollbar';
};

subtest 'a theme switch reaches the other composite widgets' => sub {
	require Term::Fabulous::Widget::Accordion;
	require Term::Fabulous::Widget::Accordion::Item;
	require Term::Fabulous::Widget::Dialog;
	require Term::Fabulous::Widget::Toast;
	require Term::Fabulous::Widget::Divider;
	require Term::Fabulous::Widget::ProgressBar;

	my $accordion = Term::Fabulous::Widget::Accordion->new( item_borders => 1, layout => { sizing => { width => sizing_fixed(20) } } );
	$accordion->add_child( Term::Fabulous::Widget::Accordion::Item->new( title => 'One', open => 1 ) );
	my $toast   = Term::Fabulous::Widget::Toast->new( kind => 'success', title => 'Saved', message => 'done' );
	my $divider = Term::Fabulous::Widget::Divider->new( text => 'x' );
	my $bar     = Term::Fabulous::Widget::ProgressBar->new( value => 50, layout => { sizing => { width => sizing_fixed(10) } } );
	my $root    = Term::Fabulous::Widget::Box->new( layout => { layout_direction => Clay::XS::CLAY_TOP_TO_BOTTOM() } );
	$root->add_child( $accordion, $toast, $divider, $bar );
	my $first = $Theme->new( palette => { text => '#101010', success => '#202020', outline => '#303030', accent => '#404040', disabled => '#505050' } );
	my $ui    = static( $root, theme => $first );
	$ui->render_lines;
	my ($item) = $accordion->items;
	is $accordion->title_color, [ 16, 16, 16, 255 ], 'accordion.title from the theme';
	is $item->border_color,     [ 80, 80, 80, 255 ], 'an item with item_borders takes accordion.border.color';
	is $toast->kind_color,      [ 32, 32, 32, 255 ], 'toast.success from the theme';
	is $toast->border_color,    [ 32, 32, 32, 255 ], 'and the toast border wears it';
	is $divider->color,         [ 48, 48, 48, 255 ], 'divider.line.color from the theme';
	is $bar->color,             [ 64, 64, 64, 255 ], 'progress.color from the theme';

	$ui->theme( $Theme->new( palette => { success => '#ff0000', disabled => '#00ff00' } ) );
	$ui->render_lines;
	is $toast->border_color, [ 255, 0,   0, 255 ], 'a switch recolors the toast';
	is $item->border_color,  [ 0,   255, 0, 255 ], 'and the accordion items';

	my $dialog = Term::Fabulous::Widget::Dialog->new( layout => { sizing => { width => sizing_fixed(10) } } );
	is $dialog->backdrop_color,             $Theme->default->token('backdrop'), 'the backdrop color is the theme\'s';
	is $dialog->to_config->{border}{color}, $Theme->default->token('accent'),   'and so is the dialog border';
	$dialog->backdrop_color('#ff00ff');
	is $dialog->backdrop_color, [ 255, 0, 255, 255 ], 'an explicit backdrop color';
};

subtest 'painted widgets repaint after a switch' => sub {
	my $divider = Term::Fabulous::Widget::Divider->new;
	my @before  = $divider->paint_key;
	Term::Fabulous::Theme::bump_generation();
	isnt [ $divider->paint_key ], \@before, 'the paint key changes with the theme generation';
};

# A chart that counts how often it paints.
my $chart_paints = 0;

class CountingChart :isa(Term::Fabulous::Widget::LineChart) {

	method paint :override () {
		$chart_paints++;
		return $self->SUPER::paint;
	}
}

subtest 'a theme switch repaints a chart' => sub {
	my $chart = CountingChart->new( labels => [qw(a b)], series => [ { name => 'cpu', data => [ 1, 2 ] } ] );
	my $root  = Term::Fabulous::Widget::Box->new( background_color => '#202020', layout => { sizing => { width => sizing_fixed(20), height => sizing_fixed(6) } } );    # the same in both themes
	$root->add_child($chart);
	my $ui = Term::Fabulous->new( root => $root, width => 20, height => 6, terminal => Term::Fabulous::Terminal::Memory->new( width => 20, height => 6 ) );
	$ui->step;
	is $chart_paints, 1, 'the first frame paints the chart';
	$ui->step;
	is $chart_paints, 1, 'a frame that changes nothing does not';
	$ui->theme('light');
	$ui->step;
	is $chart_paints, 2, 'a theme switch does, like every Display';
};

# A gauge with a themed parameter of two kinds that records what its
# looks_changed hook hears.
class Gauge :isa(Term::Fabulous::Widget::Display) {
	field @heard;

	method theme_family :common () { return 'progress' }

	method themed_params :common () {
		return ( $class->SUPER::themed_params, fill_color => [ 'color', 'normal', 'cell_color' ], track_color => [ 'track', 'normal', 'optional_color' ] );
	}

	method fill_color  (@new) { return @new ? $self->set_look( fill_color  => $new[0] ) : $self->look_value('fill_color') }
	method track_color (@new) { return @new ? $self->set_look( track_color => $new[0] ) : $self->look_value('track_color') }

	method looks_changed (@names) {
		push @heard, [@names];
		return;
	}

	method heard () {
		my @all = @heard;
		@heard = ();
		return \@all;
	}

	method natural_size () { return ( 4, 1 ) }
	method paint ()        { return }
}
$INC{'Gauge.pm'} = __FILE__;    # for the layout's use

subtest 'looks_changed hears every change of a look' => sub {
	my $gauge = Gauge->new( fill_color => '#ff0000' );
	is $gauge->heard,                                                   [],                        'the constructor records a given look without calling it';
	is [ $gauge->fill_color, $gauge->has_look_override('fill_color') ], [ [ 255, 0, 0, 255 ], 1 ], 'the given look is explicit';

	$gauge->fill_color('#00ff00');
	is $gauge->heard, [ ['fill_color'] ], 'set_look, through the accessor: the name';
	$gauge->reset_look( 'fill_color', 'track_color' );
	is $gauge->heard, [ [ 'fill_color', 'track_color' ] ], 'reset_look: the names, in one call';
	$gauge->forget_looks;
	is $gauge->heard, [], 'forget_looks outside a UI: nothing (the looks are read when the widget is drawn)';

	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($gauge);
	my $all = [ [qw(background_color border_color bordered fill_color track_color)] ];
	my $ui  = Term::Fabulous->new( root => $root, width => 10, height => 2, terminal => Term::Fabulous::Terminal::Memory->new( width => 10, height => 2 ) );
	is $gauge->heard, $all, 'a new UI: every look, once';
	$ui->theme('light');
	is $gauge->heard, $all, 'a theme switch: every look, once';
	$root->remove_child($gauge);
	is $gauge->heard, [], 'leaving the tree: nothing';
	$root->add_child($gauge);
	is $gauge->heard, $all, 'joining a tree in a UI (forget_looks): every look';
};

subtest 'a themed parameter of a kind' => sub {
	like dies { Gauge->new( fill_color => 'nope' ) }, qr/\AGauge: fill_color must be a color, got 'nope'/, 'the constructor checks by the kind';
	my $gauge = Gauge->new;
	like dies { $gauge->fill_color(undef) }, qr/\AGauge: fill_color must be a color, got undef \(reset_look\('fill_color'\) returns it to the theme\)/,
		'undef is no color; the message names reset_look';
	is $gauge->fill_color,                                                                            $dark->look( progress => 'color' ), 'and leaves the look';
	is [ $gauge->track_color(undef), $gauge->track_color, $gauge->has_look_override('track_color') ], [ undef, undef, 1 ],                'an optional kind takes undef: none';
	like dies { $gauge->track_color('nope') }, qr/\AGauge: track_color must be a color, got 'nope'/, 'and checks the rest';

	is { Gauge->themed_layout_properties }, { bordered => 'border_sides', fill_color => 'color', track_color => 'scalar' }, 'the kinds declare the layout properties (an optional color takes #null)';
	my $built = Term::Fabulous::Layout->new( string => qq{use Gauge as Gauge\nGauge { fill_color "#0000ff"; track_color #null; }\n} )->build;
	is [ $built->fill_color, $built->track_color, $built->has_look_override('track_color') ], [ [ 0, 0, 255, 255 ], undef, 1 ], 'so a layout sets them';
};

class BadKind :isa(Term::Fabulous::Widget::Display) {
	method theme_family :common () { return 'progress' }
	method themed_params :common () { return ( $class->SUPER::themed_params, fill_color => [ 'color', 'normal', 'shade' ] ) }
	method natural_size () { return ( 1, 1 ) }
	method paint () { return }
}

class StrayForward :isa(Term::Fabulous::Widget::Box) {
	method forwarded_looks :common () { return ( children => [ 'Term::Fabulous::Widget::Tabs::Bar', 'glow_color' ] ) }
}

class DoubleForward :isa(Term::Fabulous::Widget::Box) {
	method forwarded_looks :common () { return ( children => [ 'Term::Fabulous::Widget::Box', 'background_color' ] ) }
}

subtest 'declarations are checked once, when the class is first used' => sub {
	like dies { BadKind->new },
qr/BadKind: themed parameter 'fill_color' has an unknown kind 'shade' \(known: border_sides, border_style, cell_color, color, grid_border_style, optional_cell_color, optional_color, or a code reference\)/,
		'an unknown kind dies';
	like dies { StrayForward->new }, qr/StrayForward: forwarded look 'glow_color' is not a themed parameter of Term::Fabulous::Widget::Tabs::Bar with a kind/,
		'a forwarded look the part does not have dies';
	like dies { DoubleForward->new }, qr/DoubleForward: forwarded look 'background_color' is not a themed parameter of Term::Fabulous::Widget::Box with a kind/,
		'so does one the part keeps outside the role';
};

subtest 'forwarded looks live on the parts' => sub {
	my $tabs = Term::Fabulous::Widget::Tabs->new( line_color => '#ff0000' );
	is [ $tabs->line_color, $tabs->has_look_override('line_color') ], [ [ 255, 0, 0, 255 ], 1 ], 'Tabs: the constructor gives the look to the bar';
	ok lives { $tabs->reset_look('line_color') }, 'reset_look takes a look of the bar';
	is [ $tabs->line_color, $tabs->has_look_override('line_color'), $tabs->bar->has_look_override('line_color') ], [ $dark->look( tabs => 'line.color' ), 0, 0 ],
		'and returns it to the theme';
	is $tabs->text_color('#00ff00'), [ 0, 255, 0, 255 ], 'the writer returns the checked look';
	is $tabs->bar->text_color,       [ 0, 255, 0, 255 ], 'which the bar keeps';
	like dies { $tabs->reset_look('glow') }, qr/reset_look does not know 'glow' \(known: active_text_color, background_color, border_color, bordered, disabled_color, focus_border_color, /,
		'the known names include the forwarded ones';

	my $box  = Term::Fabulous::Widget::ScrollBox->new( id => 'log', thumb_color => '#ff0000' );
	my @bars = $box->_scrollbars;
	is [ map { $_->thumb_color } @bars ], [ ( [ 255, 0, 0, 255 ] ) x 2 ], 'ScrollBox: both scrollbars take the color';
	ok lives { $box->reset_look('thumb_color') }, 'reset_look takes a look of the scrollbars';
	is [ $box->thumb_color, $box->has_look_override('thumb_color'), map { $_->has_look_override('thumb_color') } @bars ], [ $dark->look( scrollbar => 'thumb' ), 0, 0, 0 ],
		'and returns both to the theme';
	like dies { $box->thumb_color(undef) }, qr/\ATerm::Fabulous::Widget::ScrollBox: thumb_color must be a color, got undef \(reset_look\('thumb_color'\) returns it to the theme\)/,
		'undef dies in the name of the box, naming reset_look';
	like dies { Term::Fabulous::Widget::ScrollBox->new( id => 'x', track_color => 'nope' ) }, qr/\ATerm::Fabulous::Widget::ScrollBox: track_color must be a color, got 'nope'/,
		'so does a bad color given to the constructor';

	my $ui = static( $box, theme => 'light' );
	is $box->thumb_color, $light->look( scrollbar => 'thumb' ), 'returned to the theme, the scrollbars follow it';
};

done_testing;
