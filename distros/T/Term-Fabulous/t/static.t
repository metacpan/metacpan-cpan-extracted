use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Encode qw(decode);
use Object::Pad 0.825;
use Clay::XS
	qw(sizing_grow sizing_fit sizing_fixed CLAY_TOP_TO_BOTTOM CLAY_LEFT_TO_RIGHT_WRAP CLAY_BACK_TO_FRONT CLAY_ALIGN_X_RIGHT CLAY_ALIGN_Y_BOTTOM CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_LEFT_TOP);
use Clay::UI::Role::Layout::HasFloating;
use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Render::Target::Grid;
use Term::Fabulous::Termbox qw(TB_DEFAULT TB_BOLD TB_DIM TB_ITALIC TB_UNDERLINE TB_BLINK TB_INVISIBLE TB_STRIKEOUT TB_OVERLINE);

sub page {
	my (%args) = @_;
	my $root = Term::Fabulous::Widget::Box->new(
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => $args{height} // sizing_fit() },
			padding          => { left  => 1,             right  => 1 },
		},
		bordered     => 1,
		border_style => Term::Fabulous::Enum::BorderStyle->Round,
		border_color => [ 200, 0, 0, 255 ],
		( $args{background} ? ( background_color => $args{background} ) : () ),
	);
	$root->add_child( Term::Fabulous::Widget::Text->new( text => $_, text_color => [ 255, 255, 255, 255 ] ) ) foreach @{ $args{lines} // ['Hello'] };
	return Term::Fabulous::Static->new( root => $root, width => $args{width} // 12, %{ $args{static} // {} } );
}

subtest 'plain text' => sub {
	my @lines = page( lines => [ 'Hello', 'Grüße' ] )->render_lines( colors => 0 );
	is \@lines,                                                  [ "╭──────────╮", "│ Hello    │", "│ Grüße    │", "╰──────────╯" ], 'border, padding and text, no rows beyond the content';
	is page( lines => ['Hello'] )->render_string( colors => 0 ), "╭──────────╮\n│ Hello    │\n╰──────────╯\n",                       'render_string ends every row with a newline';
};

subtest 'trailing whitespace' => sub {
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(3), height => sizing_fixed(1) } } );
	$root->add_child( Term::Fabulous::Widget::Text->new( text => 'ab' ) );
	is [ Term::Fabulous::Static->new( root => $root, width => 10 )->render_lines( colors => 0 ) ], ['ab'], 'default-background spaces at the end of a row are dropped';
	is [ Term::Fabulous::Static->new( root => $root, width => 3, trim_trailing_whitespace => 0 )->render_lines( colors => 0 ) ], ['ab '], 'rows are padded to the width when trimming is off';

	$root->background_color( [ 1, 2, 3, 255 ] );
	is [ Term::Fabulous::Static->new( root => $root, width => 10 )->render_lines( colors => 0 ) ], ['ab '], 'spaces in a colored background are kept';
};

subtest 'height' => sub {
	is scalar( my @rows = page( height => sizing_grow(), static => { height => 6 } )->render_lines( colors => 0 ) ), 6, 'a growing root fills the given height';
	is scalar( my @fit  = page()->render_lines( colors => 0 ) ), 3, 'a fitting root ends after its content';
};

subtest 'colors' => sub {
	my ($line) = page( lines => ['Hi'] )->render_lines;
	is $line, "\e[38;2;200;0;0m╭──────────╮\e[0m", 'a row in one color is one SGR run, reset at the end';

	my @lines = page( lines => ['Hi'], background => [ 10, 20, 30, 255 ] )->render_lines;
	is $lines[1], "\e[38;2;200;0;0;48;2;10;20;30m│\e[0m\e[48;2;10;20;30m \e[0m\e[38;2;255;255;255;48;2;10;20;30mHi\e[0m\e[48;2;10;20;30m       \e[0m\e[38;2;200;0;0;48;2;10;20;30m│\e[0m",
		'foreground and background change per run, background spaces keep only the background';

	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(1), height => sizing_fixed(1) } }, background_color => [ 0, 0, 0, 255 ] );
	is [ Term::Fabulous::Static->new( root => $root, width => 1 )->render_lines ], ["\e[48;2;0;0;0m \e[0m"], 'opaque black is emitted as black, not as the default';

	my $grid = Term::Fabulous::Render::Target::Grid->new;
	$grid->set_cell( 0, 0, 'a', 0xFF0000 | TB_BOLD | TB_DIM | TB_ITALIC | TB_UNDERLINE | TB_BLINK | TB_INVISIBLE | TB_STRIKEOUT | TB_OVERLINE, TB_DEFAULT );
	is $grid->row_text( 0, columns => 1, colors => 1 ), "\e[1;2;3;4;5;8;9;53;38;2;255;0;0ma\e[0m", 'every style bit has its SGR code';

	$root = Term::Fabulous::Widget::Box->new(
		layout       => { sizing => { width => sizing_fixed(2), height => sizing_fixed(1) } }, bordered     => 1,
		border_style => Term::Fabulous::Enum::BorderStyle->Panel,                              border_color => [ 9, 9, 9, 255 ]
	);
	like [ Term::Fabulous::Static->new( root => $root, width => 2 )->render_lines ]->[0], qr/\e\[7;38;2;9;9;9m/, 'reverse video locations use SGR 7';
};

class FloatingBox :isa(Term::Fabulous::Widget::Box) :does(Clay::UI::Role::Layout::HasFloating) { }

subtest 'translucent background' => sub {

	# A half-black box floating over the middle of red text on white.
	my $row_with_overlay = sub {
		my ($glyphs_show_through) = @_;
		my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(5), height => sizing_fixed(1) } }, background_color => [ 255, 255, 255, 255 ] );
		$root->add_child( Term::Fabulous::Widget::Text->new( text => 'abcde', text_color => [ 255, 0, 0, 255 ] ) );
		$root->add_child(
			FloatingBox->new(
				layout              => { sizing => { width => sizing_fixed(3), height => sizing_fixed(1) } },
				background_color    => [ 0, 0, 0, 128 ],
				glyphs_show_through => $glyphs_show_through,
				floating => { attach_to => CLAY_ATTACH_TO_PARENT, offset => { x => 1, y => 0 }, attach_points => { element => CLAY_ATTACH_POINT_LEFT_TOP, parent => CLAY_ATTACH_POINT_LEFT_TOP } },
			)
		);
		return ( Term::Fabulous::Static->new( root => $root, width => 5 )->render_lines )[0];
	};
	is $row_with_overlay->(0), "\e[38;2;255;0;0;48;2;255;255;255ma\e[0m\e[48;2;127;127;127m   \e[0m\e[38;2;255;0;0;48;2;255;255;255me\e[0m",
		'the glyphs below are covered with spaces in the blended color';
	is $row_with_overlay->(1), "\e[38;2;255;0;0;48;2;255;255;255ma\e[0m\e[38;2;127;0;0;48;2;127;127;127mbcd\e[0m\e[38;2;255;0;0;48;2;255;255;255me\e[0m",
		'with glyphs_show_through the text shows through, tinted';
};

subtest 'scroll box' => sub {
	my $log = Term::Fabulous::Widget::ScrollBox->new(
		id           => 'log',
		layout       => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_fixed(4) } },
		bordered     => 1,
		border_style => Term::Fabulous::Enum::BorderStyle->Round,
	);
	$log->add_child( Term::Fabulous::Widget::Text->new( text => "line $_" ) ) foreach 1 .. 9;
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
	$root->add_child($_) foreach $log, Term::Fabulous::Widget::Text->new( text => 'below' );

	is [ Term::Fabulous::Static->new( root => $root, width => 9 )->render_lines( colors => 0 ) ], [ "╭───────╮", "│line 1┃│", "│line 2││", "╰───────╯", "below" ],
		'content beyond the box is clipped, the scrollbar takes the last column and the layout continues after the box';
};

subtest 'flow layout' => sub {
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_LEFT_TO_RIGHT_WRAP, sizing => { width => sizing_grow() }, child_gap => 1, line_gap => 1 } );
	$root->add_child( Term::Fabulous::Widget::Text->new( text => $_ ) ) foreach qw(one two three four);

	is [ Term::Fabulous::Static->new( root => $root, width => 13 )->render_lines( colors => 0 ) ], [ 'one two three', '', 'four' ], 'a child that does not fit starts a new line, line_gap rows below';
	is [ Term::Fabulous::Static->new( root => $root, width => 9 )->render_lines( colors => 0 ) ], [ 'one two', '', 'three', '', 'four' ], 'a narrower root breaks the lines earlier';
};

subtest 'stack layout' => sub {
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_BACK_TO_FRONT, child_alignment => { x => CLAY_ALIGN_X_RIGHT, y => CLAY_ALIGN_Y_BOTTOM } } );
	$root->add_child(
		Term::Fabulous::Widget::Box->new(
			bordered     => 1,
			border_style => Term::Fabulous::Enum::BorderStyle->Round,
			layout       => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		),
		Term::Fabulous::Widget::Text->new( text => "first\nsecond\nthird" ),
		Term::Fabulous::Widget::Text->new( text => '*' ),
	);

	is [ Term::Fabulous::Static->new( root => $root, width => 20 )->render_lines( colors => 0 ) ], [ "first╮", "second", "third*" ],
		'the stack fits its largest child, a growing child fills it and later children are drawn on top';
};

subtest 'after_draw' => sub {
	my $root = Term::Fabulous::Widget::Box->new;
	my $ui   = Term::Fabulous::Static->new( root => $root, width => 4, height => 1 );
	my @ran;
	$ui->after_draw(
		sub {
			push @ran, 'first';
			$ui->after_draw( sub { push @ran, 'next frame' } );
		}
	);
	is \@ran, [], 'nothing runs before a frame';
	$ui->draw;
	is \@ran, ['first'], 'runs once, after the frame';
	$ui->draw;
	is \@ran, [ 'first', 'next frame' ], 'one it queued runs after the following frame';
	$ui->draw;
	is scalar @ran, 2, 'and only once';
	like dies { $ui->after_draw('later') }, qr/after_draw needs a code reference, got 'later'/, 'anything else dies';
};

subtest 'print' => sub {
	my $output = '';
	open my $fh, '>', \$output or die $!;
	page( lines => ['Grüße'] )->print( fh => $fh );
	close $fh;
	is decode( 'UTF-8', $output ), "╭──────────╮\n│ Grüße    │\n╰──────────╯\n", 'UTF-8 bytes without colors on a non-terminal handle';
	like dies { page()->print( fh   => 'not a handle' ) }, qr/fh must be an open file handle/,                           'invalid handle dies';
	like dies { page()->print( file => \*STDERR ) },       qr/print does not accept file \(known options: fh, colors\)/, 'unknown print option dies';
	like dies { page()->render_lines( colour => 0 ) }, qr/render_lines does not accept colour/, 'unknown render_lines option dies';
};

subtest 'construction' => sub {
	like dies { Term::Fabulous::Static->new( root => Term::Fabulous::Widget::Box->new, width => 10, bogus => 1 ) }, qr/bogus/, 'unknown parameters die';
	like dies {
		Term::Fabulous::Static->new( root => Term::Fabulous::Widget::Box->new, width => 10, measure_text => sub { } )
	}, qr/measure_text cannot be replaced/, 'measure_text dies';
	is( Term::Fabulous::Static->new( root => Term::Fabulous::Widget::Box->new, width => 10 )->height, 4096, 'default height' );
	is( Term::Fabulous::Static->new( root => Term::Fabulous::Widget::Box->new, width => 10, height => 7 )->height, 7, 'explicit height' );
};

done_testing;
