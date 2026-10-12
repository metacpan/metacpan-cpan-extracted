use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Termbox qw(TB_BOLD TB_ITALIC TB_UNDERLINE TB_REVERSE TB_DIM TB_BLINK TB_STRIKEOUT TB_OVERLINE TB_INVISIBLE);
use Term::Fabulous::Text::Style qw(parse_style style compose_styles apply_style);

my $untouched = { set => 0, clear => 0, color => undef, background => undef };

subtest 'style words' => sub {
	is parse_style(''), $untouched, 'an empty string touches nothing';
	is parse_style('bold'),          { %$untouched, set   => TB_BOLD },             'one bit';
	is parse_style('bold italic'),   { %$untouched, set   => TB_BOLD | TB_ITALIC }, 'bits add up';
	is parse_style('strikethrough'), { %$untouched, set   => TB_STRIKEOUT },        'strikethrough is strike';
	is parse_style('not bold'),      { %$untouched, clear => TB_BOLD },             'not clears';
	is parse_style('bold not bold'), { %$untouched, clear => TB_BOLD },             'the last word wins';
	is parse_style('not bold bold'), { %$untouched, set   => TB_BOLD },             'in both directions';
	is parse_style(' dim  blink '),  { %$untouched, set   => TB_DIM | TB_BLINK },   'whitespace does not matter';
	is parse_style('underline reverse overline conceal')->{set}, TB_UNDERLINE | TB_REVERSE | TB_OVERLINE | TB_INVISIBLE, 'every bit has a word';
};

subtest 'colors' => sub {
	is parse_style('#ff8800'),           { %$untouched, color      => [ 255, 136, 0,   255 ] }, 'hex color';
	is parse_style('rgb(1, 2, 3)'),      { %$untouched, color      => [ 1,   2,   3,   255 ] }, 'rgb() with spaces is one word per part';
	is parse_style('SteelBlue'),         { %$untouched, color      => [ 70,  130, 180, 255 ] }, 'a web color name';
	is parse_style('steelblue'),         { %$untouched, color      => [ 70,  130, 180, 255 ] }, 'in any case';
	is parse_style('default'),           { %$untouched, color      => [ 0,   0,   0,   0 ] },   'default is the terminal color';
	is parse_style('on #202020'),        { %$untouched, background => [ 32,  32,  32,  255 ] }, 'on sets the background';
	is parse_style('red on default'),    { %$untouched, color => [ 255, 0, 0, 255 ], background => [ 0, 0, 0, 0 ] },                   'both';
	is parse_style('bold red on black'), { %$untouched, set => TB_BOLD, color => [ 255, 0, 0, 255 ], background => [ 0, 0, 0, 255 ] }, 'all together';
};

subtest 'errors' => sub {
	like dies { parse_style('shiny') },    qr/^Term::Fabulous::Text::Style: unknown style word 'shiny' in 'shiny' \(known: blink, bold/, 'unknown word, with the known ones';
	like dies { parse_style('not red') },  qr/'not' needs a style word after it/,                                                        'not takes a bit';
	like dies { parse_style('bold not') }, qr/'not' needs a style word/,                                                                 'not at the end';
	like dies { parse_style('on') },       qr/'on' needs a color after it/,                                                              'on at the end';
	like dies { parse_style('on bold') },  qr/'on' needs a color/,                                                                       'on takes a color';
	like dies { parse_style(undef) },      qr/a style is a string/,                                                                      'undef';
	like dies { parse_style( ['bold'] ) }, qr/a style is a string/,                                                                      'a reference';
};

subtest 'style accepts strings and hashes' => sub {
	is style('bold'), { %$untouched, set => TB_BOLD }, 'a string is parsed';
	is style( { set => TB_BOLD, color => '#ff0000' } ), { %$untouched, set => TB_BOLD, color => [ 255, 0, 0, 255 ] }, 'a hash is completed and its colors converted';
	my $given = { background => [ 1, 2, 3 ] };
	my $got   = style($given);
	is $got, { %$untouched, background => [ 1, 2, 3, 255 ] }, 'alpha defaults to opaque';
	ref_is_not $got, $given, 'a new hash';
	like dies { style( { shade =>  1 } ) },      qr/unknown style key\(s\) shade \(known: set, clear, color, background\)/, 'unknown key';
	like dies { style( { set   => -1 } ) },      qr/set/,                                                                   'bits are non-negative integers';
	like dies { style( { color => 'shiny' } ) }, qr/color/,                                                                 'colors are checked';
	like dies { style( [] ) }, qr/a style is a string or a hash reference/, 'an array';
};

subtest 'compose_styles' => sub {
	is compose_styles(), $untouched, 'no styles touch nothing';
	is compose_styles( parse_style('bold red'), parse_style('italic blue') ), { %$untouched, set => TB_BOLD | TB_ITALIC, color => [ 0, 0, 255, 255 ] }, 'bits add up, the later color wins';
	is compose_styles( parse_style('bold'),       parse_style('not bold') ), { %$untouched, clear => TB_BOLD }, 'clear after set clears';
	is compose_styles( parse_style('not bold'),   parse_style('bold') ),     { %$untouched, set   => TB_BOLD }, 'set after clear sets';
	is compose_styles( parse_style('on #000000'), parse_style('dim'), parse_style('not dim') ), { %$untouched, clear => TB_DIM, background => [ 0, 0, 0, 255 ] },
		'a background stays until a later one replaces it';
	my ( $outer, $inner ) = ( parse_style('bold underline'), parse_style('not bold red') );
	my $look = { attrs => TB_ITALIC, color => [ 1, 1, 1, 255 ], background => [ 2, 2, 2, 255 ] };
	is apply_style( $look, compose_styles( $outer, $inner ) ), apply_style( apply_style( $look, $outer ), $inner ), 'applying the composed style is applying each in turn';
	is $outer, { %$untouched, set => TB_BOLD | TB_UNDERLINE }, 'the given styles are not changed';
};

subtest 'apply_style' => sub {
	my $look = { attrs => TB_ITALIC | TB_BOLD, color => [ 1, 1, 1, 255 ], background => undef };
	is apply_style( $look, parse_style('underline not bold red') ), { attrs => TB_ITALIC | TB_UNDERLINE, color => [ 255, 0, 0, 255 ], background => undef }, 'bits cleared and set, color replaced';
	is apply_style( $look, parse_style('on #000000') ), { attrs => TB_ITALIC | TB_BOLD, color => [ 1, 1, 1, 255 ], background => [ 0, 0, 0, 255 ] }, 'untouched parts stay';
	is $look, { attrs => TB_ITALIC | TB_BOLD, color => [ 1, 1, 1, 255 ], background => undef }, 'the given look is not changed';
};

done_testing;
