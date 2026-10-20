use v5.32;
use warnings;
use utf8;

use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM CLAY_TEXT_WRAP_NEWLINES CLAY_TEXT_WRAP_NONE);
use Term::Fabulous::Layout;
use Term::Fabulous::Static;
use Term::Fabulous::Termbox qw(TB_BOLD TB_ITALIC TB_UNDERLINE TB_DEFAULT);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Color;
use Term::Fabulous::Render::Attr qw(color_attr);
use Term::Fabulous::Theme;

my $plain = { set => 0, clear => 0, color => undef, background => undef };

sub _attr ($rgba) {
	return defined $rgba ? color_attr( Term::Fabulous::Color->new( color => $rgba ) ) : undef;
}

subtest 'text and color' => sub {
	my $text = Term::Fabulous::Widget::Text->new( id => 'title', text => 'Grüße', text_color => '#ff8000' );
	is [ $text->id, $text->text, $text->text_color ], [ 'title', 'Grüße', [ 255, 128, 0, 255 ] ], 'a color string becomes [r, g, b, a]';
	$text->text_color('rgb(1, 2, 3)');
	is $text->text_color, [ 1, 2, 3, 255 ], 'also when set later';
	$text->text('Hallo');
	is $text->text, 'Hallo', 'the text can change';
	like dies { Term::Fabulous::Widget::Text->new( text => 'x', text_color => 'nope' ) }, qr/\ATerm::Fabulous::Widget::Text: text_color must be a color, got 'nope'/, 'an invalid color dies';
	like dies { $text->text_color('nope') },                                              qr/\ATerm::Fabulous::Widget::Text: text_color must be a color, got 'nope'/, 'also when set later';
	is $text->text_color, [ 1, 2, 3, 255 ], 'and leaves the color as it was';
};

subtest 'bold, italic and underline' => sub {
	require Term::Fabulous::Static;
	require Term::Fabulous::Widget::Box;
	my $text = Term::Fabulous::Widget::Text->new( text => 'Bold', text_color => '#ffffff', bold => 1 );
	is [ $text->bold, $text->italic, $text->underline ], [ 1, 0, 0 ],                        'readers';
	is $text->style_attrs,                               Term::Fabulous::Termbox::TB_BOLD(), 'style_attrs of bold text';
	$text->italic('yes');
	$text->underline(1);
	is $text->style_attrs, Term::Fabulous::Termbox::TB_BOLD() | Term::Fabulous::Termbox::TB_ITALIC() | Term::Fabulous::Termbox::TB_UNDERLINE(), 'all three';
	like dies { $text->bold( [] ) }, qr/bold must be a plain boolean value/, 'a reference dies';

	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($text);
	my $ui = Term::Fabulous::Static->new( root => $root, width => 10, height => 1 );
	$ui->draw;
	like( ( $ui->render_lines( colors => 1 ) )[0], qr/\e\[1;3;4;38;2;255;255;255mBold/, 'the cells carry the attributes' );
};

subtest 'spans and markup' => sub {
	my $text = Term::Fabulous::Widget::Text->new( text => 'error: file', spans => [ [ 0, 5, 'bold red' ], [ 7, 11, { set => TB_UNDERLINE } ] ] );
	is $text->text,   'error: file',                                                                                                       'a Text underneath';
	is $text->spans,  [ [ 0, 5, { %$plain, set => TB_BOLD, color => [ 255, 0, 0, 255 ] } ], [ 7, 11, { %$plain, set => TB_UNDERLINE } ] ], 'spans with normalized styles';
	is $text->markup, undef,                                                                                                               'no markup when given as spans';

	my $marked = Term::Fabulous::Widget::Text->new( markup => 'Press [bold]Enter[/]' );
	is [ $marked->text, $marked->markup ], [ 'Press Enter', 'Press [bold]Enter[/]' ],  'markup gives the text and keeps itself';
	is $marked->spans,                     [ [ 6, 11, { %$plain, set => TB_BOLD } ] ], 'and the spans';

	$marked->markup('[underline]a[/]b');
	is [ $marked->text, $marked->spans ], [ 'ab', [ [ 0, 1, { %$plain, set => TB_UNDERLINE } ] ] ], 'markup can be set later';
	$marked->text('plain');
	is [ $marked->text, $marked->spans, $marked->markup ], [ 'plain', [], undef ], 'setting the text drops the spans and the markup';
	ref_is $marked->stylize( 'bold', 1, 3 ), $marked, 'stylize chains';
	is $marked->stylize('on #000000')->spans, [ [ 1, 3, { %$plain, set => TB_BOLD } ], [ 0, 5, { %$plain, background => [ 0, 0, 0, 255 ] } ] ], 'stylize appends, the whole text by default';
	is $marked->clear_spans->spans,           [],                                                                                               'clear_spans';
	$marked->markup('[bold]x[/]yz');
	my $revision = $marked->content_revision;
	is $marked->spans( [ [ 1, 3, 'italic' ] ] ),                   [ [ 1, 3, { %$plain, set => TB_ITALIC } ] ], 'spans replaces them all and returns the new ones';
	is [ $marked->markup, $marked->content_revision > $revision ], [ undef, 1 ],                                'which ends the markup and counts as a change';
};

subtest 'errors' => sub {
	like dies { Term::Fabulous::Widget::Text->new( markup => '[bold]x', text => 'x' ) },             qr/markup cannot be given together with text or spans/,  'markup or text';
	like dies { Term::Fabulous::Widget::Text->new( markup => '[shiny]x' ) },                         qr/unknown style word 'shiny'/,                          'invalid markup';
	like dies { Term::Fabulous::Widget::Text->new( spans => 'bold' ) },                              qr/spans must be an array reference/,                    'spans is an array';
	like dies { Term::Fabulous::Widget::Text->new( spans => [ [ 0, 1 ] ] ) },                        qr/a span is \[start, end, style\]/,                     'a span has three parts';
	like dies { Term::Fabulous::Widget::Text->new( text => 'ab', spans => [ [ 1, 0, 'bold' ] ] ) },  qr/span end 0 lies before its start 1/,                  'end before start';
	like dies { Term::Fabulous::Widget::Text->new( text => 'ab', spans => [ [ 0, 3, 'bold' ] ] ) },  qr/span end 3 lies past the text \(2 characters\)/,      'past the end';
	like dies { Term::Fabulous::Widget::Text->new( text => 'ab', spans => [ [ -1, 1, 'bold' ] ] ) }, qr/span start must be a non-negative integer, got '-1'/, 'negative start';
	my $text = Term::Fabulous::Widget::Text->new( text => 'ab' );
	like dies { $text->stylize( 'shiny', 0, 1 ) }, qr/unknown style word 'shiny'/, 'stylize checks the style';
	like dies { $text->markup('[/]') },            qr/without an open tag/,        'markup checks the markup';
	is [ $text->text, $text->spans ], [ 'ab', [] ], 'and leaves the widget as it was';
};

subtest 'line_styles' => sub {
	my $text = Term::Fabulous::Widget::Text->new( text => 'abcdefgh', spans => [ [ 2, 6, 'bold #ff0000' ], [ 4, 8, 'not bold on #0000ff' ] ] );
	is $text->line_styles( 0, 8 ),
		[ [ 2, 0, 0, undef, undef ], [ 2, TB_BOLD, 0, 0xFF0000, undef ], [ 2, 0, TB_BOLD, 0xFF0000, 0x0000FF ], [ 2, 0, TB_BOLD, undef, 0x0000FF ] ],
		'runs at every span boundary; a later span clears what an earlier one set';
	is $text->line_styles( 3, 2 ), [ [ 1, TB_BOLD, 0, 0xFF0000, undef ], [ 1, 0, TB_BOLD, 0xFF0000, 0x0000FF ] ], 'a line in the middle gets its part of the runs';
	is $text->line_styles( 6, 0 ), [],                                                                            'an empty line has no runs';
	my $unstyled = Term::Fabulous::Widget::Text->new( text => 'ab' );
	is $unstyled->line_styles( 0, 2 ), [], 'no runs without spans: the renderer paints it plain';
	my $default = Term::Fabulous::Widget::Text->new( text => 'ab', spans => [ [ 0, 2, 'default' ] ] );
	is $default->line_styles( 0, 2 ), [ [ 2, 0, 0, TB_DEFAULT, undef ] ], 'default is the terminal color, not an untouched one';
};

subtest 'links' => sub {
	my $text = Term::Fabulous::Widget::Text->new( markup => 'See [link=perlfunc]perlfunc[/] and [bold][link=perlop]perlop[/][/].' );
	is $text->text,                                     'See perlfunc and perlop.',                      'markup gives the text';
	is $text->links,                                    [ [ 4, 12, 'perlfunc' ], [ 17, 23, 'perlop' ] ], 'and the links, in order';
	is $text->spans,                                    [ [ 17, 23, { %$plain, set => TB_BOLD } ] ],     'the style is a span, the link is none';
	is [ map { $text->link_at($_) } 3, 4, 11, 12, 17 ], [ undef, 0, 0, undef, 1 ],                       'link_at';

	my $target = { page => 'perlvar' };
	ref_is $text->add_link( $target, 0, 3 ), $text,   'add_link chains';
	ref_is $text->links->[0][2],             $target, 'any value is a target, kept as it is';
	is $text->markup, undef, 'and the markup no longer says what the text is';
	like dies { $text->add_link( 'x',   10, 14 ) }, qr/the link 10 to 14 overlaps the link 4 to 12/, 'links do not overlap';
	like dies { $text->add_link( 'x',   2,  2 ) },  qr/a link must not be empty/,                    'nor are they empty';
	like dies { $text->add_link( undef, 13, 14 ) }, qr/a link needs a target/,                       'a target is required';
	like dies { Term::Fabulous::Widget::Text->new( text => 'ab', links => [ [ 0, 3, 'x' ] ] ) }, qr/link end 3 lies past the text/, 'offsets are checked';

	$text->text('plain');
	is $text->links,              [], 'setting the text drops the links';
	is $text->clear_links->links, [], 'clear_links';
};

subtest 'selecting and activating links' => sub {
	my $text = Term::Fabulous::Widget::Text->new( markup => '[link=a]A[/] [link=b]B[/]' );
	my @activated;
	$text->on( LinkActivate => sub ($event) { push @activated, [ $event->link, $event->index, $event->start, $event->end ]; return } );

	is $text->selected_link,                                  undef,                'nothing selected at first';
	is [ $text->select_next_link, $text->selected_link ],     [ 1, 0 ],             'next selects the first link';
	is [ $text->select_next_link, $text->selected_link ],     [ 1, 1 ],             'then the next one';
	is [ $text->select_next_link, $text->selected_link ],     [ 0, 1 ],             'and stops at the last';
	is $text->activate_link,                                  1,                    'activate_link follows the selected link';
	is \@activated,                                           [ [ 'b', 1, 2, 3 ] ], 'LinkActivate with the target and the range';
	is [ $text->select_previous_link, $text->selected_link ], [ 1, 0 ],             'previous goes back';
	is [ $text->select_previous_link, $text->selected_link ], [ 0, 0 ],             'and stops at the first';

	$text->add_link( 'c', 1, 2 );
	is $text->selected_link, 0, 'a link added after the selected one keeps the selection';
	$text->select_link(undef);
	is $text->activate_link, 0, 'nothing to activate without a selection';
	like dies { $text->select_link(3) }, qr/link 3 is not a link; the text has 3 links/, 'select_link checks the index';
};

subtest 'link looks and focus' => sub {
	my $theme = Term::Fabulous::Theme->default;
	my %attr  = map { my ( $slot, $state ) = @$_; ( "$slot.$state" => _attr( $theme->look( 'text', $slot, $state ) ) ) } map {
		my $slot = $_;
		map { [ $slot, $_ ] } qw(normal hovered selected)
	} 'link', 'link.background';
	my $text = Term::Fabulous::Widget::Text->new( markup => 'a [link=x]bc[/]' );
	is $text->line_styles( 0, 4 ), [ [ 2, 0, 0, undef, undef ], [ 2, TB_UNDERLINE, 0, $attr{'link.normal'}, $attr{'link.background.normal'} ] ], 'a link is underlined in the theme\'s link color';
	$text->hover_link(0);
	is $text->line_styles( 2, 2 ), [ [ 2, TB_UNDERLINE, 0, $attr{'link.hovered'}, $attr{'link.background.hovered'} ] ], 'the hovered look';
	$text->select_link(0);
	is $text->line_styles( 2, 2 ), [ [ 2, 0, TB_UNDERLINE, $attr{'link.selected'}, $attr{'link.background.selected'} ] ], 'the selected look wins and is not underlined';

	is $text->accepts_focus, 1, 'a Text with links takes the focus';
	is( Term::Fabulous::Widget::Text->new( text   => 'x' )->accepts_focus,                        0, 'one without links does not' );
	is( Term::Fabulous::Widget::Text->new( markup => '[link=x]y[/]', can_focus => 0 )->can_focus, 0, 'can_focus => 0 opts out' );
};

subtest 'wrapped lines keep their styles' => sub {
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(7), height => sizing_fixed(2) } } );
	$root->add_child( Term::Fabulous::Widget::Text->new( markup => 'ab [bold]cd ef[/] gh', text_color => '#ffffff' ) );
	my $ui = Term::Fabulous::Static->new( root => $root, width => 7, height => 2 );
	$ui->draw;
	my @lines = $ui->render_lines( colors => 1 );
	is $lines[0], "\e[38;2;255;255;255mab \e[0m\e[1;38;2;255;255;255mcd\e[0m", 'the first line ends in the bold span';
	is $lines[1], "\e[1;38;2;255;255;255mef\e[0m\e[38;2;255;255;255m gh\e[0m", 'the second line starts in it';
};

subtest 'a KDL layout sets markup' => sub {
	my $text = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Text as Text
Text "hint" {
	markup "Press [bold]Enter[/]"
	italic #true
}
KDL
	is [ $text->id, $text->text, $text->italic ], [ 'hint', 'Press Enter', 1 ],               'markup and the Text properties';
	is $text->spans,                              [ [ 6, 11, { %$plain, set => TB_BOLD } ] ], 'the spans';
	like dies { Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Text as Text\nText { markup 1 }" )->build }, qr/'markup' needs a string argument/, 'markup is a string';
};

subtest 'highlights are painted over the spans and under the links' => sub {
	my $text = Term::Fabulous::Widget::Text->new( text => 'abcdef', spans => [ [ 0, 6, 'bold' ] ] );
	$text->highlights( [ [ 2, 4, 'on #0000ff' ] ] );
	is $text->highlights,          [ [ 2, 4, { %$plain, background => [ 0, 0, 255, 255 ] } ] ],                                              'highlights are normalized like spans';
	is $text->line_styles( 0, 6 ), [ [ 2, TB_BOLD, 0, undef, undef ], [ 2, TB_BOLD, 0, undef, 0x0000FF ], [ 2, TB_BOLD, 0, undef, undef ] ], 'a highlight adds to the spans under it';
	is $text->spans,               [ [ 0, 6, { %$plain, set => TB_BOLD } ] ],                                                                'the spans are untouched';
	$text->clear_highlights;
	is [ $text->highlights, $text->line_styles( 0, 6 ) ], [ [], [ [ 6, TB_BOLD, 0, undef, undef ] ] ], 'clear_highlights';
	$text->highlights( [ [ 0, 1, 'red' ] ] );
	$text->text('new');
	is $text->highlights, [], 'setting the text drops the highlights';
	like dies { $text->highlights( [ [ 0, 9, 'red' ] ] ) }, qr/highlight end 9 lies past the text/,    'offsets are checked';
	like dies { $text->highlights('bold') },                qr/highlights must be an array reference/, 'and the shape';
};

subtest 'a palette token in a style is the theme\'s color when the text paints' => sub {
	my $theme = Term::Fabulous::Theme->default;
	my $text  = Term::Fabulous::Widget::Text->new( text => 'ab', spans => [ [ 0, 2, 'bold accent on surface_low' ] ] );
	is $text->spans, [ [ 0, 2, { %$plain, set => TB_BOLD, color => 'accent', background => 'surface_low' } ] ], 'the span keeps the token names';
	is $text->line_styles( 0, 2 ), [ [ 2, TB_BOLD, 0, _attr( $theme->token('accent') ), _attr( $theme->token('surface_low') ) ] ], 'painted in the theme\'s colors';
	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($text);
	my $light = Term::Fabulous::Static->new( root => $root, width => 10, height => 1, theme => 'light' );
	$light->draw;
	is $text->line_styles( 0, 2 )->[0][3], _attr( Term::Fabulous::Theme->builtin('light')->token('accent') ), 'in another UI, in that theme\'s colors';
};

subtest 'content_revision counts the changes of the content' => sub {
	my $text = Term::Fabulous::Widget::Text->new( text => 'abc' );
	my @seen = ( $text->content_revision );
	$text->stylize( 'bold', 0, 1 );
	push @seen, $text->content_revision;
	$text->add_link( 'x', 1, 2 );
	push @seen, $text->content_revision;
	$text->markup('[bold]x[/]');
	push @seen, $text->content_revision;
	$text->clear_spans;
	push @seen, $text->content_revision;
	$text->clear_links;
	push @seen, $text->content_revision;
	$text->text('other');
	push @seen, $text->content_revision;
	is [ map { $seen[$_] > $seen[ $_ - 1 ] ? 1 : 0 } 1 .. $#seen ], [ (1) x 6 ], 'every change of the text, the spans, the markup or the links counts';
	my $before = $text->content_revision;
	$text->highlights( [ [ 0, 1, 'red' ] ] );
	$text->add_link( 'y', 0, 2 );
	my $with_link = $text->content_revision;
	$text->select_link(0);
	$text->hover_link(0);
	is [ $text->content_revision > $before, $text->content_revision == $with_link ], [ 1, 1 ], 'highlights, the selected and the hovered link do not count';
};

subtest 'the Searchable role' => sub {
	my $text = Term::Fabulous::Widget::Text->new( text => 'find me' );
	ok $text->DOES('Term::Fabulous::Role::Searchable'), 'a Text is searchable';
	is [ $text->search_texts ],       [ [ undef, 'find me' ] ], 'one text with no key';
	is $text->search_revision(undef), $text->content_revision,  'the revision is the content revision';
	$text->highlight_text( undef, [ [ 5, 7, 'on selection' ] ] );
	is $text->highlights, [ [ 5, 7, { %$plain, background => 'selection' } ] ], 'highlight_text sets the highlights';
	$text->clear_text_highlights;
	is $text->highlights,              [],               'clear_text_highlights clears them';
	is $text->reveal_text( undef, 5 ), [ $text, undef ], 'reveal_text names the text itself and no row';
};

sub laid_out_rows ( $text, $columns ) {
	my $box = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed($columns) } } );
	$box->add_child($text);
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($box);
	my $ui = Term::Fabulous::Static->new( root => $root, width => 40, height => 30 );
	$ui->draw;
	return $ui->bounding_box($box)->{height};
}

subtest 'estimated_rows wraps as Clay does' => sub {
	my $NBSP  = "\x{a0}";
	my @texts = (
		[ 'aaaa bbbb cccc',                                          9 ],
		[ 'xx aaaaaaaaaaaa bb',                                      10 ],
		[ "aa bb${NBSP}cc dd",                                       6 ],
		[ 'Grüße wörld 日本語 text',                                    8 ],
		[ 'one two three four five six seven eight nine ten eleven', 12 ],
		[ "two\nlines here\nand three",                              6 ],
	);
	is [ map { Term::Fabulous::Widget::Text->new( text => $_->[0] )->estimated_rows( $_->[1] ) } @texts ],
		[ map { laid_out_rows( Term::Fabulous::Widget::Text->new( text => $_->[0] ), $_->[1] ) } @texts ],
		'the rows of every text';
	is( Term::Fabulous::Widget::Text->new( text => "a b c\nd e f", wrap_mode => CLAY_TEXT_WRAP_NEWLINES )->estimated_rows(2), 2, 'newlines: one row per line' );
	is( Term::Fabulous::Widget::Text->new( text => "a b c\nd e f", wrap_mode => CLAY_TEXT_WRAP_NONE )->estimated_rows(2),     1, 'none: one row, newlines included, as Clay lays it out' );
	is( Term::Fabulous::Widget::Text->new->estimated_rows(5), 0, 'an empty text takes no row, as in Clay' );
	like dies { Term::Fabulous::Widget::Text->new( text => 'x' )->estimated_rows(0) }, qr/columns must be a positive integer, got '0'/, 'a text wraps to a column at least';
};

subtest 'row_of_offset' => sub {
	my @rows_of = (
		[ 'aaaa bbbb cccc',     0,  8,  0, 'the first character' ],
		[ 'aaaa bbbb cccc',     4,  8,  0, 'a space belongs to the word before it' ],
		[ 'aaaa bbbb cccc',     5,  8,  1, 'the next word is on the next row' ],
		[ 'aaaa bbbb cccc',     99, 8,  2, 'past the end is the last row' ],
		[ 'xx aaaaaaaaaaaa bb', 16, 10, 2, 'after a word wider than the row' ],
		[ "aa bb\ncc dd ee",    9,  5,  2, 'a line break starts a row, and the rows of the lines before count' ],
	);
	is( Term::Fabulous::Widget::Text->new( text => $_->[0] )->row_of_offset( @$_[ 1, 2 ] ), $_->[3], $_->[4] ) foreach @rows_of;
	is( Term::Fabulous::Widget::Text->new( text => "a b\nc d", wrap_mode => CLAY_TEXT_WRAP_NEWLINES )->row_of_offset( 6, 1 ), 1, 'without wrapping at words, the line is the row' );
	is( Term::Fabulous::Widget::Text->new( text => "a b\nc d", wrap_mode => CLAY_TEXT_WRAP_NONE )->row_of_offset( 6, 1 ),     0, 'none keeps the whole text on the first row' );
	like dies { Term::Fabulous::Widget::Text->new( text => 'x' )->row_of_offset( -1, 3 ) }, qr/offset must be a non-negative integer/, 'the offset is checked';
};

done_testing;
