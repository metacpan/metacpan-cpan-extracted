use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Termbox qw(TB_BOLD TB_ITALIC);
use Term::Fabulous::Text::Markup qw(parse_markup);
use Term::Fabulous::Text::Style qw(parse_style);

my $bold   = parse_style('bold');
my $italic = parse_style('italic');

subtest 'tags become spans' => sub {
	is [ parse_markup('plain') ],              [ 'plain',      [], [] ], 'no tags, no spans';
	is [ parse_markup('a [bold]b[/] c') ],     [ 'a b c',      [ [ 2, 3, $bold ] ],  [] ], '[/] closes the innermost tag';
	is [ parse_markup('[bold]ab[/bold]c') ],   [ 'abc',        [ [ 0, 2, $bold ] ],  [] ], '[/style] closes it by name';
	is [ parse_markup('[bold]to the end') ],   [ 'to the end', [ [ 0, 10, $bold ] ], [] ], 'an open tag runs to the end';
	is [ parse_markup('[ bold ]x[/ bold ]') ], [ 'x',          [ [ 0, 1, $bold ] ],  [] ], 'spaces inside the brackets are ignored';
	is [ parse_markup('[bold][/]x') ],         [ 'x',          [], [] ], 'an empty span is dropped';
	is [ parse_markup("[bold]\x{e9}t\x{e9}[/] \x{3042}") ], [ "\x{e9}t\x{e9} \x{3042}", [ [ 0, 3, $bold ] ], [] ], 'offsets count characters';
};

subtest 'nesting' => sub {
	my ( $text, $spans ) = parse_markup('[bold]a[italic]b[/]c[/]');
	is $text,  'abc',                                  'text';
	is $spans, [ [ 0, 3, $bold ], [ 1, 2, $italic ] ], 'outer span first';

	( $text, $spans ) = parse_markup('[bold][italic]x[/][/]');
	is $spans, [ [ 0, 1, $bold ], [ 0, 1, $italic ] ], 'same start: the outer one first, so the inner one wins';

	( $text, $spans ) = parse_markup('[bold]a[italic]b[/bold]c[/italic]');
	is $spans, [ [ 0, 2, $bold ], [ 1, 3, $italic ] ], 'closing by name reaches past an inner tag';
};

subtest 'links' => sub {
	is [ parse_markup('See [link=https://perl.org]perl.org[/link].') ], [ 'See perl.org.', [], [ [ 4, 12, 'https://perl.org' ] ] ], 'a link tag gives a link, no span';
	is [ parse_markup('[ link = perlfunc/open ]open[/]') ],             [ 'open',          [], [ [ 0, 4,  'perlfunc/open' ] ] ],    '[/] closes it; blanks around the target go';
	my ( $text, $spans, $links ) = parse_markup('[bold]a [link=x]b[/bold] c[/link] [link=y]d[/]');
	is $text,                                'a b c d',                        'styles and links nest';
	is $spans,                               [ [ 0, 3, $bold ] ],              'the style is a span';
	is $links,                               [ [ 2, 5, 'x' ], [ 6, 7, 'y' ] ], 'the links in order, each with its target';
	is [ parse_markup('[link=x][/link]y') ], [ 'y', [], [] ],                  'an empty link is dropped';
	like dies { parse_markup('[link=]x') },                 qr/link tag \[link=\] without a target/,     'a link needs a target';
	like dies { parse_markup('[link=a]x[link=b]y[/][/]') }, qr/link tag \[link=b\] inside another link/, 'links do not nest';
	like dies { parse_markup('[link]x') },                  qr/unknown style word 'link'/,               'link without = is no tag of its own';
};

subtest 'text that is not a tag' => sub {
	is [ parse_markup('\[bold] stays') ],   [ '[bold] stays',    [], [] ], 'an escaped bracket is text';
	is [ parse_markup('a\b') ],             [ 'a\b',             [], [] ], 'other backslashes stay';
	is [ parse_markup('item [1] and []') ], [ 'item [1] and []', [], [] ], 'digits and nothing are not tags';
	is [ parse_markup('open [ only') ],     [ 'open [ only',     [], [] ], 'a lone bracket';
};

subtest 'errors' => sub {
	like dies { parse_markup('[/]') },              qr/^Term::Fabulous::Text::Markup: closing tag \[\/\] without an open tag in '\[\/\]'/, 'nothing to close';
	like dies { parse_markup('[bold]x[/italic]') }, qr/closing tag \[\/italic\] does not match an open tag/,                               'no such open tag';
	like dies { parse_markup('[shiny]x') },         qr/^Term::Fabulous::Text::Style: unknown style word 'shiny'/,                          'an invalid style dies at once';
	like dies { parse_markup(undef) },              qr/markup is a string/,                                                                'undef';
	like dies { parse_markup( [] ) },               qr/markup is a string/,                                                                'a reference';
};

done_testing;
