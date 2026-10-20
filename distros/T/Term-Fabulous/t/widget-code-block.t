use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Object::Pad 0.825;

use Clay::XS qw(sizing_fixed sizing_grow);
use Term::Fabulous;
use Term::Fabulous::Color;
use Term::Fabulous::Document::Look;
use Term::Fabulous::Render::Attr qw(color_attr);
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Termbox qw(TB_BOLD TF_KEY_MOUSE_WHEEL_RIGHT);
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::CodeBlock;

# A code block 12 columns wide (10 for the code, a margin on either
# side) in a 20 x 5 memory terminal.
sub code_ui (%parameters) {
	my $code = Term::Fabulous::Widget::CodeBlock->new( layout => { sizing => { width => sizing_fixed(12) } }, %parameters );
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($code);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 5 );
	my $ui       = Term::Fabulous->new( root => $root, width => 20, height => 5, terminal => $terminal );
	$ui->step;
	return ( $code, $terminal, $ui );
}

sub screen ($terminal) {
	return [ map { s/\s+\z//r } $terminal->lines ];
}

sub attr_of ($color) {
	return color_attr( Term::Fabulous::Color->new( color => $color ) );
}

subtest 'parameters' => sub {
	like dies { Term::Fabulous::Widget::CodeBlock->new( code => [] ) },                                   qr/code must be a string/,                          'code is a string';
	like dies { Term::Fabulous::Widget::CodeBlock->new( language => '' ) },                               qr/language must not be empty/,                     'a language has a name';
	like dies { Term::Fabulous::Widget::CodeBlock->new( highlighter => 'perl' ) },                        qr/highlighter must be a code reference/,           'a highlighter is code';
	like dies { Term::Fabulous::Widget::CodeBlock->new( code => 'ab', spans => [ [ 0, 3, 'bold' ] ] ) },  qr/span end 3 lies past the text \(2 characters\)/, 'spans lie within the code';
	like dies { Term::Fabulous::Widget::CodeBlock->new( code => 'ab', spans => [ [ 0, 1, 'shiny' ] ] ) }, qr/shiny/,                                          'span styles are checked';
	my $code = Term::Fabulous::Widget::CodeBlock->new( code => "a\n\nlonger" );
	is [ $code->line_count, $code->widest_line_columns, [ $code->natural_size ]->[1] ], [ 3, 6, 3 ], 'as tall as the code has lines';
};

subtest 'painting and clipping' => sub {
	my ( $code, $terminal ) = code_ui( code => "short\nexactly 10\nlonger than ten" );
	is screen($terminal), [ ' short', ' exactly 10', " longer tha\x{203A}", '', '' ], 'lines that do not fit are cut at the margin and marked';

	my $look = Term::Fabulous::Document::Look->of($code);
	my ( undef, $fg, $bg ) = @{ $terminal->cell( 1, 0 ) };
	is [ $fg, $bg ],                  [ attr_of( $look->style('code_block')->{color} ), attr_of( $look->style('code_block')->{background} ) ], 'in the code_block look of the theme';
	is $terminal->cell( 11, 0 )->[2], attr_of( $look->style('code_block')->{background} ),                                                     'the background fills the block';
};

subtest 'scrolled sideways' => sub {
	my ( $code, $terminal, $ui ) = code_ui( code => "short\nlonger than ten" );
	is $code->max_offset, 5, 'the widest line decides how far the code scrolls';
	$code->offset(99);
	$ui->step;
	is [ $code->offset, $code->shown_offset ], [ 99, 5 ], 'an offset beyond the end is kept, and the end is shown';
	is screen($terminal), [ "\x{2039}", "\x{2039}r than ten", q(), q(), q() ], 'the code moves left, with the marks of what is hidden';

	my @wheel_seen;
	$ui->root->on( Mouse => sub ($event) { push @wheel_seen, $event->key; return } );
	$terminal->mouse( key => TF_KEY_MOUSE_WHEEL_RIGHT, x => 3, y => 0 );
	$ui->step;
	is \@wheel_seen, [TF_KEY_MOUSE_WHEEL_RIGHT], 'the block leaves the wheel to the widgets around it';
};

subtest 'highlighter and spans' => sub {
	my @calls;
	my ( $code, $terminal, $ui ) = code_ui(
		code        => 'my $x;',
		language    => 'perl',
		highlighter => sub ( $text, $language ) { push @calls, [ $text, $language ]; return [ [ 0, 2, 'bold #ff0000' ], [ 3, 5, '#00ff00' ] ] },
		spans       => [ [ 4, 5, 'on #0000ff' ] ],
	);
	is \@calls,                                  [ [ 'my $x;', 'perl' ] ],                   'the highlighter gets the code and the language';
	is $terminal->cell( 1, 0 )->[1],             attr_of('#ff0000') | TB_BOLD,               'its spans style the code';
	is [ @{ $terminal->cell( 5, 0 ) }[ 1, 2 ] ], [ attr_of('#00ff00'), attr_of('#0000ff') ], 'the program\'s spans apply on top';

	$code->spans( [] );
	$ui->step;
	is scalar @calls, 1, 'the highlighter result is kept while the code stays';
	$code->language('kdl');
	$ui->step;
	is $calls[-1][1], 'kdl', 'a new language asks again';

	$code->highlighter( sub { 'nonsense' } );
	like dies { $ui->step }, qr/highlighter spans must be an array reference/, 'a highlighter that returns no spans dies';
};

subtest 'a theme switch repaints in the new colors' => sub {
	my ( $code, $terminal, $ui ) = code_ui( code => 'my $x;', highlighter => sub { [ [ 0, 2, 'bold' ] ] } );
	$ui->theme('light');
	$ui->step;
	my $light = Term::Fabulous::Document::Look->of($code);
	is [ @{ $terminal->cell( 4, 0 ) }[ 1, 2 ] ], [ attr_of( $light->style('code_block')->{color} ), attr_of( $light->style('code_block')->{background} ) ], 'the cached runs follow the theme';
};

# A UI that draws one part of its tree in the light theme.
class My::SubtreeUI :isa(Term::Fabulous) {
	field $light_part :param;

	method theme_for :override ($widget) {
		return Term::Fabulous::Theme->builtin('light') if $light_part->contains($widget);
		return $self->SUPER::theme_for($widget);
	}
}

subtest 'a subtree theme reaches the background and the spans' => sub {
	my $code = Term::Fabulous::Widget::CodeBlock->new( code => 'my $x;', spans => [ [ 0, 2, 'on accent' ] ], layout => { sizing => { width => sizing_fixed(12) } } );
	my $part = Term::Fabulous::Widget::Box->new;
	$part->add_child($code);
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($part);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 5 );
	my $ui       = My::SubtreeUI->new( root => $root, width => 20, height => 5, terminal => $terminal, light_part => $part );
	$ui->step;
	my ( $light, $dark ) = map { Term::Fabulous::Theme->builtin($_) } qw(light dark);
	my $light_look = Term::Fabulous::Document::Look->new( theme => $light );
	isnt attr_of( $light_look->style('code_block')->{background} ), attr_of( Term::Fabulous::Document::Look->new( theme => $dark )->style('code_block')->{background} ), 'the two themes differ';
	is $terminal->cell( 11, 0 )->[2], attr_of( $light_look->style('code_block')->{background} ), 'the background is the subtree theme\'s';
	is $terminal->cell( 1,  0 )->[2], attr_of( $light->token('accent') ),                        'and so are the colors of the spans';
	ref_is( Term::Fabulous::Document::Look->of($code)->theme, $light, 'Look->of asks the theme the widget draws with' );
};

# A look that paints code on another background.
class My::CodeLook :isa(Term::Fabulous::Document::Look) {

	method recipes :common () {
		return ( $class->SUPER::recipes, code_block => { color => 'text', background => 'accent' } );
	}
}

subtest 'look_class' => sub {
	my ( $code, $terminal, $ui ) = code_ui( code => 'my $x;', look_class => 'My::CodeLook' );
	my $look = My::CodeLook->of($code);
	is $terminal->cell( 4, 0 )->[2], attr_of( $look->style('code_block')->{background} ), 'the block paints with the styles of its look class';
	$code->look_class('Term::Fabulous::Document::Look');
	$ui->step;
	is $terminal->cell( 4, 0 )->[2], attr_of( Term::Fabulous::Document::Look->of($code)->style('code_block')->{background} ), 'and repaints when the class changes';
	like dies { Term::Fabulous::Widget::CodeBlock->new( look_class => 'Term::Fabulous::Widget::Box' ) }, qr/look_class must be the name of a Term::Fabulous::Document::Look class/,
		'another class dies';
	like dies { Term::Fabulous::Widget::CodeBlock->new( look_class => 'No::Such::Look' ) }, qr/look_class must be the name of a Term::Fabulous::Document::Look class/, 'and so does an unknown one';
};

subtest 'KDL' => sub {
	require Term::Fabulous::Layout;
	my $root = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::CodeBlock as CodeBlock
CodeBlock "example" {
	code "a\nb"
	language "perl"
	offset 2
}
KDL
	is [ $root->code, $root->language, $root->offset ], [ "a\nb", 'perl', 2 ], 'code, language and offset can be set in a layout';
};

subtest 'highlights, tokens and the search role' => sub {
	my ( $code, $terminal, $ui ) = code_ui( code => "my \$x;\nmy \$y;", spans => [ [ 0, 2, 'bold' ] ] );
	ok $code->DOES('Term::Fabulous::Role::Searchable'), 'a code block is searchable';
	is [ $code->search_texts ], [ [ undef, "my \$x;\nmy \$y;" ] ], 'its one text is the code';
	my $revealed = $code->reveal_text( undef, 8 );
	ref_is $revealed->[0], $code, 'reveal_text names the widget';
	is $revealed->[1], 1, 'and the line of the offset';
	$code->highlight_text( undef, [ [ 3, 5, 'on accent' ] ] );
	$ui->step;
	is $code->highlights, [ [ 3, 5, { set => 0, clear => 0, color => undef, background => 'accent' } ] ], 'highlight_text sets the highlights, tokens kept';
	is [ @{ $terminal->cell( 4, 0 ) }[ 1, 2 ] ], [ attr_of( Term::Fabulous::Document::Look->of($code)->style('code_block')->{color} ) | 0, attr_of( $ui->theme->token('accent') ) ],
		'painted in the theme\'s color over the spans';
	is $terminal->cell( 1, 0 )->[1], attr_of( Term::Fabulous::Document::Look->of($code)->style('code_block')->{color} ) | TB_BOLD, 'the spans stay';
	my $revision = $code->content_revision;
	$code->clear_text_highlights;
	is [ $code->highlights, $code->content_revision ], [ [], $revision ], 'clear_text_highlights clears them without counting as a change';
	$code->code('other');
	is [ $code->content_revision > $revision, $code->search_revision(undef) ], [ 1, $code->content_revision ], 'new code counts, and search_revision says so';
	$revision = $code->content_revision;
	ref_is $code->stylize( 'bold', 0, 2 ), $code, 'stylize appends a span, as on a Text';
	is [ scalar @{ $code->spans }, $code->content_revision > $revision ], [ 1, 1 ], 'and the spans count as content';
	is $code->clear_spans->spans,                                         [],       'clear_spans';
};

done_testing;
