use v5.32;
use warnings;
use utf8;

use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use File::Temp qw(tempfile);
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Theme;
use Term::Fabulous::Theme::Document;

my $Theme = 'Term::Fabulous::Theme';

sub theme ($kdl) {
	return $Theme->from_string($kdl);
}

subtest 'a complete theme file' => sub {
	my $theme = theme(<<'KDL');
theme "nord" extends="light"

palette {
	accent "#88c0d0"
	surface "rgb(46, 52, 64)"
}

button {
	background "surface_raised"
	border style=Round color="border"
	text "text"
	focused { border color="accent" }
	pressed { background "reverse" }
	disabled { text "disabled" }
	variant "primary" {
		border color="accent"
		focused { border color="text_bright" }
	}
}

input {
	border style=none enabled=#true
	focused { background "focus_background" }
}

table {
	header.text "text_bright"
}
KDL
	my $light = $Theme->builtin('light');
	is $theme->name, 'nord', 'the name from the theme node';
	ref_is $theme->extends, $light, 'extends from the theme node';
	is $theme->token('accent'),                [ 136, 192, 208, 255 ],          'a hex palette color';
	is $theme->token('surface'),               [ 46, 52, 64, 255 ],             'an rgb() palette color';
	is $theme->token('text'),                  $light->token('text'),           'other tokens come from the parent';
	is $theme->look( 'button', 'background' ), $light->token('surface_raised'), 'a slot node with one value';
	ref_is $theme->look( 'button', 'border.style' ), Term::Fabulous::Enum::BorderStyle->Round, 'border style= sets border.style';
	is $theme->look( 'button', 'border.color' ),                         $light->token('border'),           'border color= sets border.color';
	is $theme->look( 'button', 'border.color', 'focused' ),              [ 136, 192, 208, 255 ],            'a state node';
	is $theme->look( 'button', 'background', 'pressed' ),                'reverse',                         'reverse';
	is $theme->look( 'button', 'text', 'disabled' ),                     $light->token('disabled'),         'a state slot by token';
	is $theme->look( 'button', 'border.color', 'normal', ['primary'] ),  [ 136, 192, 208, 255 ],            'a variant';
	is $theme->look( 'button', 'border.color', 'focused', ['primary'] ), $light->token('text_bright'),      'a state inside a variant';
	is $theme->look( 'input', 'border.style' ),                          undef,                             'style=none';
	is $theme->look( 'input', 'border.enabled' ),                        1,                                 'enabled=#true';
	is $theme->look( 'input', 'background', 'focused' ),                 $light->token('focus_background'), 'another family';
	is $theme->look( 'table', 'header.text' ),                           $light->token('text_bright'),      'a dotted slot name';
};

subtest 'an empty theme' => sub {
	my $theme = theme('');
	is $theme->name, undef, 'no name';
	ref_is $theme->extends, $Theme->default, 'extends dark';
	is $theme->look( 'button', 'border.color', 'focused' ), $Theme->default->token('accent'), 'and looks like it';
};

subtest '#null is none' => sub {
	my $theme = theme(<<'KDL');
dialog { background #null; border style=#null }
KDL
	is $theme->look( 'dialog', 'background' ),   undef, 'a null value';
	is $theme->look( 'dialog', 'border.style' ), undef, 'a null property';
};

subtest 'from_file' => sub {
	my ( $fh, $path ) = tempfile( SUFFIX => '.kdl', UNLINK => 1 );
	binmode $fh, ':encoding(UTF-8)';
	print {$fh} qq{theme "Grüße"\npalette { accent "#102030" }\n};
	close $fh;
	my $theme = $Theme->from_file($path);
	is $theme->name,            'Grüße',             'a file is read as UTF-8';
	is $theme->token('accent'), [ 16, 32, 48, 255 ], 'and its palette applied';

	like dies { $Theme->from_file('/nonexistent/theme.kdl') }, qr{cannot open '/nonexistent/theme.kdl'},   'a missing file dies';
	like dies { $Theme->from_file(undef) },                    qr/from_file needs a file name, got undef/, 'undef dies';
	like dies { $Theme->from_string( [] ) },                   qr/from_string needs a string/,             'from_string with a reference dies';

	( $fh, $path ) = tempfile( SUFFIX => '.kdl', UNLINK => 1 );
	print {$fh} "button { glow \"accent\" }\n";
	close $fh;
	like dies { $Theme->from_file($path) }, qr/\ATerm::Fabulous::Theme: theme file '\Q$path\E': slot 'button.glow': the family button has no slot 'glow'/, 'an error names the file';
};

subtest 'invalid theme files die with the node' => sub {
	my %error_of = (
		'theme "a"; theme "b"'                                    => qr/the 'theme' node may appear only once/,
		'theme "a" "b"'                                           => qr/the 'theme' node takes at most one argument/,
		'theme 1'                                                 => qr/the theme's name must be a string/,
		'theme { x }'                                             => qr/the 'theme' node has no children/,
		'theme "a" extends=1'                                     => qr/extends must be the name of a built-in theme/,
		'theme extends="neon"'                                    => qr/extends names an unknown built-in theme 'neon'/,
		'theme "a" author="me"'                                   => qr/the 'theme' node knows only the property 'extends', got 'author'/,
		'palette { }; palette { }'                                => qr/the 'palette' node may appear only once/,
		'palette "x" { }'                                         => qr/the 'palette' node takes no arguments or properties/,
		'palette { pink "#ff00ff" }'                              => qr/palette: unknown token 'pink' \(known: /,
		'palette { accent }'                                      => qr/palette token 'accent' needs exactly one string argument/,
		'palette { accent "#ffffff" { x } }'                      => qr/palette token 'accent' needs exactly one string argument/,
		'palette { accent "redd" }'                               => qr/palette token accent must be a color, got 'redd'/,
		'palette { accent "#ff0000"; accent "#00ff00" }'          => qr/palette: the token 'accent' is set twice/,
		'lamp { }'                                                => qr/unknown top-level node 'lamp' \(known: theme, palette and the families /,
		'button "x" { }'                                          => qr/button: a family node takes no arguments or properties/,
		'button { glow "accent" }'                                => qr/slot 'button.glow': the family button has no slot 'glow'/,
		'button { text }'                                         => qr/button: the node 'text' needs either one value or key=value properties/,
		'button { text "a" "b" }'                                 => qr/button: the node 'text' needs either one value or key=value properties/,
		'button { text "a" color="b" }'                           => qr/button: the node 'text' needs either one value or key=value properties/,
		'button { text { } }'                                     => qr/button: the node 'text' needs either one value or key=value properties/,
		'button { text { color "x" } }'                           => qr/button: the node 'text' has no children/,
		'button { text 1 }'                                       => qr/button.text must be a string or #null/,
		'button { border style=1 }'                               => qr/button.border.style must be a string or #null/,
		'button { text #true }'                                   => qr/button.text must be a string or #null/,
		'input { border enabled="true" }'                         => qr/input.border.enabled must be #true or #false/,
		'input { border enabled=#null }'                          => qr/input.border.enabled cannot be 'none'/,
		'button { border style=Wobbly }'                          => qr/button.border.style must be a border style, its name or 'none', got 'Wobbly'/,
		'scrollbar { track "none" }'                              => qr/scrollbar.track cannot be 'none'/,
		'scrollbar { thumb #null }'                               => qr/scrollbar.thumb cannot be 'none'/,
		'tabs { line style="Thick" }'                             => qr/tabs.line.style must be a border style with joints or its name, got 'Thick'/,
		'tabs { line style="none" }'                              => qr/tabs.line.style cannot be 'none'/,
		'button { selected { text "x" } }'                        => qr/slot 'button.text.selected': the slot button.text has no state 'selected'/,
		'button { focused "x" { } }'                              => qr/button: a state node takes no arguments or properties/,
		'button { focused { hovered { } } }'                      => qr/button: a state cannot be inside another state/,
		'button { variant { } }'                                  => qr/button: a variant needs exactly one string argument/,
		'button { variant "a b" { } }'                            => qr/button: a variant name must be a word/,
		'button { focused { variant "a" { } } }'                  => qr/button: a variant cannot be inside a state or another variant/,
		'button { variant "a" { variant "b" { } } }'              => qr/button: a variant cannot be inside a state or another variant/,
		'button { variant "a" { glow "x" } }'                     => qr/variant 'button.a': the family button has no slot 'glow'/,
		'button { text "accent"; text "danger" }'                 => qr/button: the slot 'text' is set twice/,
		'button { text "accent" }; button { text "danger" }'      => qr/button: the slot 'text' is set twice/,
		'button { focused { text "accent"; text "danger" } }'     => qr/button: the slot 'text.focused' is set twice/,
		'button { variant "p" { text "accent"; text "danger" } }' => qr/button: variant 'p': the slot 'text' is set twice/,
		'button { text "x" '                                      => qr/failed to parse KDL/,
	);
	foreach my $kdl ( sort keys %error_of ) {
		like dies { theme($kdl) }, qr/\ATerm::Fabulous::Theme: theme: /, "'$kdl' dies naming the theme";
		like dies { theme($kdl) }, $error_of{$kdl},                      "'$kdl' says why";
		ok( !Term::Fabulous::Theme::Document->parse($kdl)->is_valid, "'$kdl' is invalid in the editor's document too" );
	}
};

subtest 'valid theme files are valid in the editor too' => sub {
	foreach my $kdl (
		'palette { accent "#ff8800" }', 'theme "mine" extends="light"', 'button { text "accent"; focused { text "danger" } }', 'button { variant "primary" { text "accent" } }',
		'input { border enabled=#true style="Round" }'
		)
	{
		ok lives { theme($kdl) }, "'$kdl' loads";
		ok( Term::Fabulous::Theme::Document->parse($kdl)->is_valid, "and is valid in the editor's document" );
	}
};

done_testing;
