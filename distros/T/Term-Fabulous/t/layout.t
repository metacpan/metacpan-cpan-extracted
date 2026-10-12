use v5.32;
use warnings;
use utf8;

use Test2::V0;
use File::Temp qw(tempfile);

use Clay::XS qw(
	Clay_GetElementId CLAY__SIZING_TYPE_FIT CLAY__SIZING_TYPE_GROW CLAY_ALIGN_X_CENTER CLAY_ALIGN_Y_BOTTOM CLAY_LEFT_TO_RIGHT_WRAP CLAY_BACK_TO_FRONT CLAY_LINE_SIZING_FIT CLAY_TEXT_WRAP_NEWLINES CLAY_TEXT_ALIGN_RIGHT
	CLAY_ATTACH_TO_ELEMENT_WITH_ID CLAY_ATTACH_POINT_LEFT_TOP CLAY_ATTACH_POINT_RIGHT_BOTTOM CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH CLAY_CLIP_TO_ATTACHED_PARENT
);
use Term::Fabulous::Layout;

sub layout {
	my ($kdl) = @_;
	return Term::Fabulous::Layout->new( string => $kdl );
}

sub build {
	my ($kdl) = @_;
	return layout($kdl)->build;
}

subtest 'widget classes load on their own' => sub {
	my $code = <<'PERL';
use Term::Fabulous::Layout;
my $root = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Box as Box
Box "root" {
	border style=Round color="#ffffff"
	background_color "rgb(1, 2, 3)"
}
KDL
die "Term::Fabulous was loaded\n" if exists $INC{'Term/Fabulous.pm'};
print ref($root), "\n";
PERL
	my ( $program, $program_path ) = tempfile( UNLINK => 1 );    # a Windows command line cannot carry the lines of the program
	print {$program} $code;
	close $program;
	open my $child, '-|', $^X, ( map { "-I$_" } @INC ), $program_path or die "cannot run $^X: $!";
	my $output = do { local $/; <$child> };
	ok close($child), 'child process succeeded';
	is $output, "Term::Fabulous::Widget::Box\n", 'a Box builds with only Term::Fabulous::Layout loaded';
};

subtest 'use instructions' => sub {
	foreach my $module ( '../../tmp/x', '/abs/path', 'Foo/Bar', 'Foo::Bar.pm', 'Foo::', '::Foo' ) {
		like dies { layout(qq{use "$module" as Box\nBox}) }, qr/invalid module name '\Q$module\E'/, "path-like module '$module' is rejected";
	}
	like dies { layout("use Term::Fabulous::Widget::Box as box\nbox") }, qr/invalid widget alias 'box'/, 'lowercase alias is rejected';
	like dies { layout("use Term::Fabulous::Widget::Box as Box\nuse Term::Fabulous::Widget::Text as Box\nBox") },
		qr/alias 'Box' is declared twice/, 'duplicate alias is rejected';
	like dies { layout("use Term::Fabulous::Widget::Box Box\nBox") }, qr/invalid 'use' instruction/, 'malformed use is rejected';
	like dies { layout("use Term::Fabulous::Color as Color\nColor") },
		qr/'Term::Fabulous::Color' \(widget alias 'Color'\) does not compose Term::Fabulous::Role::CanParseLayout/,
		'a class without CanParseLayout is rejected';
};

subtest 'allowed_namespaces' => sub {
	my %allowed = ( allowed_namespaces => [ 'My::App', 'Term::Fabulous::Widget' ] );
	my $root    = Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Box as Box\nBox", %allowed )->build;
	isa_ok $root, ['Term::Fabulous::Widget::Box'], 'a module below an allowed namespace loads';
	like dies { Term::Fabulous::Layout->new( string => "use Some::Module::With::Side::Effects as Box\nBox", %allowed ) },
		qr/'use Some::Module::With::Side::Effects' is not allowed; allowed_namespaces permits only modules in My::App, Term::Fabulous::Widget/,
		'another module is refused before it is loaded (it does not exist, so loading it would fail differently)';
	like dies { Term::Fabulous::Layout->new( string => "use My::Application as Box\nBox", %allowed ) }, qr/'use My::Application' is not allowed/,
		'a namespace is matched by whole package name parts';
	like dies { Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Box as Box\nBox", allowed_namespaces => 'Term::Fabulous' ) },
		qr/allowed_namespaces must be an array reference of package names, got 'Term::Fabulous'/, 'the namespaces are a list';
	like dies { Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Box as Box\nBox", allowed_namespaces => ['Term/Fabulous'] ) },
		qr/allowed_namespaces holds an invalid package name 'Term\/Fabulous'/, 'of package names';
	like dies { Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Box as Box\nBox", allowed_namespaces => [] ) },
		qr/allowed_namespaces needs at least one package name/, 'an empty list dies';
};

subtest 'document structure' => sub {
	like dies { layout("use Term::Fabulous::Widget::Box as Box\nBox\nstray 1") },      qr/unexpected top-level node 'stray'/, 'stray top-level node';
	like dies { layout("use Term::Fabulous::Widget::Box as Box\nBox\nBox") },          qr/multiple root widgets/,             'two roots';
	like dies { build("use Term::Fabulous::Widget::Box as Box\nBox {\n\tButton\n}") }, qr/unknown widget 'Button'/,           'undeclared child widget';
	like dies { build(qq{use Term::Fabulous::Widget::Box as Box\nBox "a" "b"}) },      qr/at most one argument, a string id/, 'two ids';
};

subtest 'properties' => sub {
	my $box = "use Term::Fabulous::Widget::Box as Box\nBox {\n%s\n}";
	like dies { build( sprintf $box, 'backgroud_color "#000000"' ) },   qr/unknown layout property 'backgroud_color'/, 'misspelled property dies';
	like dies { build( sprintf $box, 'clear_children' ) },              qr/unknown layout property 'clear_children'/,  'method names cannot be called';
	like dies { build( sprintf $box, 'layout gap=1 child_gap=2' ) },    qr/not both/,                                  'gap and child_gap together';
	like dies { build( sprintf $box, 'padding 1' ) },                   qr/takes key=value properties only/,           'padding needs properties';
	like dies { build( sprintf $box, 'padding middle=1' ) },            qr/does not accept middle/,                    'unknown padding key';
	like dies { build( sprintf $box, 'sizing width="percent(150)"' ) }, qr/percentage must be in 0\.\.100/,            'percent above 100';

	my $root = build( sprintf $box, qq{sizing width="percent(50)" height="fixed(3)"\nbordered left=#true top=#true\nlayout direction=down gap=0\npadding left=1\npadding top=2} );
	is $root->layout->{sizing}{width}{percent}, 0.5, 'percent(50) becomes 0.5';
	is $root->layout->{sizing}{height}{min},    3,   'fixed(3)';
	is $root->layout->{child_gap},              0,   'gap 0 is kept';
	is $root->bordered, { left => 1, top => 1, right => 0, bottom => 0 }, 'bordered with sides';
	is $root->layout->{padding}, { left => 1, top => 2 }, 'a second padding node keeps the sides of the first';

	like dies { build( sprintf $box, 'colour "#000000"' ) },
		qr/known: background_color, border, border_color, bordered, child_alignment, classes, floating, glyphs_show_through, height_group, layout, padding, sizing, width_group\)/,
		'the known names include the structured properties';
	like dies { build( sprintf $box, '_note "x"' ) }, qr/unknown layout property '_note'/, 'a node not starting with an uppercase letter is a property';
	is build( sprintf $box, 'glyphs_show_through 1' )->glyphs_show_through, 1, 'a boolean property takes 1';
	like dies { build( sprintf $box, 'glyphs_show_through "false"' ) }, qr/'glyphs_show_through' must be #true or #false, got 'false'/, 'a boolean property rejects strings';
	is build( sprintf $box, 'bordered #true' )->bordered, { top => 1, right => 1, bottom => 1, left => 1 }, 'bordered with one boolean';
	like dies { build( sprintf $box, 'bordered top="yes"' ) }, qr/layout property 'bordered' top must be #true or #false, got 'yes'/, 'a side rejects strings';
	like dies { build( sprintf $box, 'bordered middle=#true' ) }, qr/layout property 'bordered' needs one boolean argument or boolean key=value pairs for the sides top, right, bottom and left/,
		'an unknown side dies';
	like dies { build( sprintf $box, 'glyphs_show_through #null' ) }, qr/must be #true or #false, got #null/, 'a boolean property rejects #null';
};

subtest 'sizing with minimum and maximum' => sub {
	my $box  = "use Term::Fabulous::Widget::Box as Box\nBox {\n%s\n}";
	my $root = build( sprintf $box, 'sizing width="grow( 2 , 40 )" height="fit(3)"' );
	is $root->layout->{sizing}{width},  { type => CLAY__SIZING_TYPE_GROW, min => 2, max => 40 }, 'grow(MIN, MAX)';
	is $root->layout->{sizing}{height}, { type => CLAY__SIZING_TYPE_FIT,  min => 3, max => 0 },  'fit(MIN) has no maximum';
	like dies { build( sprintf $box, 'sizing width="grow(5, 2)"' ) }, qr/sizing width minimum 5 is greater than maximum 2/, 'MIN above MAX dies';
	like dies { build( sprintf $box, 'sizing width="fit(-1)"' ) },    qr/invalid sizing width 'fit\(-1\)'/,                 'a negative MIN dies';
};

subtest 'child alignment' => sub {
	my $box  = "use Term::Fabulous::Widget::Box as Box\nBox {\n%s\n}";
	my $root = build( sprintf $box, "child_alignment x=center\nchild_alignment y=bottom" );
	is $root->layout->{child_alignment}, { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_BOTTOM }, 'a second child_alignment node keeps the other key';
	like dies { build( sprintf $box, 'child_alignment x=middle' ) }, qr/Term::Fabulous::Widget::Box: child_alignment x must be one of center, left, right, got 'middle'/, 'an unknown name dies';
};

subtest 'flow layout' => sub {
	my $box  = "use Term::Fabulous::Widget::Box as Box\nBox {\n%s\n}";
	my $root = build( sprintf $box, 'layout direction=wrap gap=1 line_gap=2 line_sizing=fit' );
	is $root->layout, { layout_direction => CLAY_LEFT_TO_RIGHT_WRAP, child_gap => 1, line_gap => 2, line_sizing => CLAY_LINE_SIZING_FIT }, 'direction=wrap with line_gap and line_sizing';
	like dies { build( sprintf $box, 'layout line_sizing=shrink' ) }, qr/layout line_sizing must be one of fit, grow, got 'shrink'/, 'an unknown line_sizing dies';
	like dies { build( sprintf $box, 'layout line_gap=-1' ) },        qr/layout line_gap must be a non-negative integer/,            'a negative line_gap dies';
};

subtest 'stack layout' => sub {
	my $root = build("use Term::Fabulous::Widget::Box as Box\nBox {\nlayout direction=stack\n}");
	is $root->layout->{layout_direction}, CLAY_BACK_TO_FRONT, 'direction=stack';
};

subtest 'floating' => sub {
	my $root = build(<<'KDL');
use Term::Fabulous::Widget::Box as Box
Box "root" {
	Box "popup" {
		floating attach_to=element parent_id=root element=left_top offset_x=-2
		floating parent=right_bottom offset_y=3 z_index=5 pointer_capture=passthrough clip_to=attached_parent
	}
}
KDL
	is $root->children->[0]->floating, {
		attach_to            => CLAY_ATTACH_TO_ELEMENT_WITH_ID,
		parent_id            => Clay_GetElementId('root')->{id},
		attach_points        => { element => CLAY_ATTACH_POINT_LEFT_TOP, parent => CLAY_ATTACH_POINT_RIGHT_BOTTOM },
		offset               => { x       => -2,                         y      => 3 },
		z_index              => 5,
		pointer_capture_mode => CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH,
		clip_to              => CLAY_CLIP_TO_ATTACHED_PARENT,
		},
		'a second floating node merges key by key';

	my $box = "use Term::Fabulous::Widget::Box as Box\nBox {\n%s\n}";
	like dies { build( sprintf $box, 'floating attach_to=element' ) }, qr/floating attach_to=element needs parent_id/,      'attaching to an element needs parent_id';
	like dies { build( sprintf $box, 'floating element=top' ) },       qr/floating element must be one of center_bottom, /, 'an unknown attach point dies';
	like dies { build( sprintf $box, 'floating z_index=1.5' ) },       qr/floating z_index must be an integer, got '1\.5'/, 'z_index must be an integer';
};

subtest 'scroll box' => sub {
	my $scroll_box = build(qq{use Term::Fabulous::Widget::ScrollBox as ScrollBox\nScrollBox "log" {\n\thorizontal #true\n\tvertical #false\n}});
	is [ $scroll_box->horizontal, $scroll_box->vertical ], [ 1, 0 ], 'horizontal and vertical';
	like dies { build("use Term::Fabulous::Widget::ScrollBox as ScrollBox\nScrollBox") }, qr/requires an explicit 'id'/, 'a ScrollBox needs an id';
};

subtest 'input widgets' => sub {
	my $root = build(<<'KDL');
use Term::Fabulous::Widget::Box as Box
use Term::Fabulous::Widget::TextField as TextField
use Term::Fabulous::Widget::TextArea as TextArea
use Term::Fabulous::Widget::Checkbox as Checkbox
use Term::Fabulous::Widget::RadioGroup as RadioGroup
use Term::Fabulous::Widget::RadioButton as RadioButton
use Term::Fabulous::Widget::Dropdown as Dropdown
use Term::Fabulous::Widget::Slider as Slider

Box {
	TextField "name" {
		max_length 10
		value "Grüße"
		mask "*"
		accent_color "#ff0000"
	}
	TextArea "notes" {
		wrap #false
		preferred_rows 3
	}
	Checkbox "terms" {
		label "Accept"
		checked #true
	}
	RadioGroup "size" {
		RadioButton { label "Small"; value "s"; }
		RadioButton { label "Large"; value "l"; }
		value "l"
	}
	Dropdown "color" {
		options "Red" "Green"
		option "Dark blue" value="navy"
		value "navy"
		disabled #true
	}
	Slider "volume" {
		max 11
		step 0.5
		value 5.5
	}
}
KDL
	my %input = map { $_->id => $_ } @{ $root->children };
	is [ $input{name}->value, $input{name}->max_length, $input{name}->mask, $input{name}->accent_color ], [ 'Grüße', 10, '*', [ 255, 0, 0, 255 ] ], 'TextField';
	is [ $input{notes}->wrap, $input{notes}->preferred_rows ],                                            [ 0, 3 ],                                 'TextArea';
	is [ $input{terms}->label, $input{terms}->checked ],                                                  [ 'Accept', 1 ],                          'Checkbox';
	is [ $input{size}->value, $input{size}->selected_button->label ],                                     [ 'l', 'Large' ],                         'RadioGroup with its buttons';
	is [ $input{color}->selected_label, $input{color}->disabled, scalar $input{color}->options ],         [ 'Dark blue', 1, 3 ],                    'Dropdown';
	is [ $input{volume}->max, $input{volume}->value ],                                                    [ 11, 5.5 ],                              'Slider';

	my $field = "use Term::Fabulous::Widget::TextField as TextField\nTextField {\n%s\n}";
	like dies { build( sprintf $field, 'max_length 2' . "\n" . 'value "abc"' ) }, qr/more than max_length 2/, 'a value longer than max_length dies';
	like dies { build("use Term::Fabulous::Widget::Dropdown as Dropdown\nDropdown {\n\toption \"a\" color=1\n}") }, qr/takes one label and optional value=\.\.\. and disabled=\.\.\./,
		'an option with an unknown property dies';
	is build("use Term::Fabulous::Widget::Dropdown as Dropdown\nDropdown {\n\tvalue \"b\"\n\toptions \"a\" \"b\"\n}")->value, 'b', 'a Dropdown value may come before its options';

	$input{color}->disabled(0);
	ok $input{color}->can_focus, 'an input disabled in the layout takes the focus once enabled';
	my $group = build("use Term::Fabulous::Widget::RadioGroup as RadioGroup\nRadioGroup {\n\tdisabled #true\n}");
	$group->disabled(0);
	ok $group->can_focus, 'so does a radio group';
	my $kept = build("use Term::Fabulous::Widget::Slider as Slider\nSlider {\n\tcan_focus #false\n\tdisabled #true\n}");
	$kept->disabled(0);
	ok !$kept->can_focus, 'can_focus #false in the layout is kept through it';
};

subtest 'text' => sub {
	my $root = build(<<'KDL');
use Term::Fabulous::Widget::Box as Box
use Term::Fabulous::Widget::Text as Text
Box "root" {
	Text "greeting" {
		text "Grüße 🎉"
		text_color "rgba(1, 2, 3, 1.0)"
	}
}
KDL
	my ($text) = $root->children->@*;
	is $text->id,         'greeting',       'Text keeps its id';
	is $text->text,       "Grüße 🎉",        'text is stored as a character string';
	is $text->text_color, [ 1, 2, 3, 255 ], 'text_color';

	my $styled = build("use Term::Fabulous::Widget::Text as Text\nText {\n\twrap_mode newlines\n\ttext_alignment right\n}");
	is [ $styled->wrap_mode, $styled->text_alignment ], [ CLAY_TEXT_WRAP_NEWLINES, CLAY_TEXT_ALIGN_RIGHT ], 'wrap_mode and text_alignment';
	is build("use Term::Fabulous::Widget::Text as Text\nText {\n\ttext_color SteelBlue\n}")->text_color, [ 70, 130, 180, 255 ], 'a color by its web name';
	like dies { build("use Term::Fabulous::Widget::Text as Text\nText {\n\twrap_mode lines\n}") }, qr/Term::Fabulous::Widget::Text: wrap_mode must be one of newlines, none, words, got 'lines'/,
		'an unknown wrap_mode dies';
	like dies { build("use Term::Fabulous::Widget::Text as Text\nText {\n\ttext_alignment top\n}") }, qr/text_alignment must be one of center, left, right, got 'top'/,
		'an unknown text_alignment dies';

	like dies { build("use Term::Fabulous::Widget::Text as Text\nText {\n\ttext\n}") },   qr/'text' needs exactly one argument/, 'text without argument';
	like dies { build("use Term::Fabulous::Widget::Text as Text\nText {\n\ttext 5\n}") }, qr/'text' needs a string argument/,    'text with a number';
};

subtest 'find_by_id' => sub {
	my $root = build(<<'KDL');
use Term::Fabulous::Widget::Box as Box
use Term::Fabulous::Widget::Text as Text
Box "root" {
	Box "panel" {
		Text "title" { text "Title"; }
	}
}
KDL
	is $root->find_by_id('root')->id,    'root',  'the widget itself is searched';
	is $root->find_by_id('title')->text, 'Title', 'a nested Text is found';
	is $root->find_by_id('missing'),     undef,   'undef for a missing id';
	like dies { $root->find_by_id(undef) }, qr/find_by_id needs an id/, 'an undefined id dies';
	my $helper = Term::Fabulous::Widget::Text->new( id => 'helper', text => 'Helper' );
	$root->find_by_id('panel')->add_internal_children($helper);
	ref_is $root->find_by_id('helper'), $helper, 'an internal child is found too';
};

done_testing;
