use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Termbox ();
use Term::Fabulous::Widget::Text;

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

done_testing;
