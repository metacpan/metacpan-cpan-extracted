use v5.32;
use warnings;
use utf8;

use Test2::V0;

use File::Temp qw(tempdir);
use FindBin;
use Term::Fabulous::Theme;
use Term::Fabulous::Theme::Document;

my $Document = 'Term::Fabulous::Theme::Document';

# The lines of two texts that differ, as [ old, new ] pairs; texts of the
# same number of lines only.
sub changed_lines {
	my ( $old, $new ) = @_;
	my @old = split /\n/, $old, -1;
	my @new = split /\n/, $new, -1;
	die "changed_lines: the texts have different numbers of lines\n" unless @old == @new;
	return [ map { [ $old[$_], $new[$_] ] } grep { $old[$_] ne $new[$_] } 0 .. $#old ];
}

subtest 'the example themes parse and keep their text' => sub {
	foreach my $file ( sort glob("$FindBin::Bin/../examples/themes/*.kdl") ) {
		my $document = $Document->read_file($file);
		my ($name) = $file =~ m{([^/]+)\.kdl\z};
		ok $document->is_valid, "$name is valid";
		isa_ok $document->theme, ['Term::Fabulous::Theme'], "$name builds a theme";
		is $document->theme->name, $name, "$name has its name";

		my ($key) = grep { /\Apalette\./ } $document->setting_keys;
		my $same = $document->with_setting( $key, $document->setting($key) );
		is $same->text, $document->text, "$name: writing a value back changes nothing";

		my $changed = $document->with_setting( $key, '#123456' );
		is changed_lines( $document->text, $changed->text ), [ [ match(qr/#[0-9a-f]{6}"/), match(qr/"#123456"/) ] ], "$name: a new value changes its line only";
	}
};

subtest 'settings, keys and lines' => sub {
	my $document = $Document->parse(<<~'KDL');
		theme "sea" extends="light"

		palette {
			accent "#5fd3c0"
		}

		button {
			border style=Round color="accent"
			focused { text "text_bright" }
			variant "primary" {
				text "accent"
			}
		}
		KDL
	ok $document->is_valid, 'valid';
	is [ $document->name, $document->extends ], [ 'sea', 'light' ], 'name and extends';
	is [ $document->setting_keys ], [ 'theme.name', 'theme.extends', 'palette.accent', 'button.border.style', 'button.border.color', 'button.text.focused', 'button[primary].text' ],
		'the keys in document order';
	is $document->setting('button.border.style'),  'Round',                     'a style';
	is $document->setting('button.text.focused'),  'text_bright',               'a state';
	is $document->setting('button.text.normal'),   undef,                       'normal may be named and is unset here';
	is $document->line_of('button[primary].text'), 11,                          'the line of a variant setting';
	is $document->line_of('button[primary]'),      10,                          'the line of a variant';
	is $document->line_of('palette.text'),         undef,                       'an unset key has no line';
	is [ $document->variants ],                    [ [ 'button', 'primary' ] ], 'the variants';
	is $document->kdl_version,                     2,                           'KDL 2';

	is $document->effective_setting('palette.accent'),               { spec => '#5fd3c0',     origin => 'set' },     'a set token';
	is $document->effective_setting('palette.text'),                 { spec => '#1e222a',     origin => 'light' },   'a token of the base theme';
	is $document->effective_setting('button.border.color.focused'),  { spec => 'accent',      origin => 'default' }, 'a state with a default of its own';
	is $document->effective_setting('button.text.hovered'),          { spec => 'text',        origin => 'normal' },  'a state that follows the normal state';
	is $document->effective_setting('button[primary].border.color'), { spec => 'accent',      origin => 'family' },  'a variant slot follows the family';
	is $document->effective_setting('button[primary].text.hovered'), { spec => 'accent',      origin => 'normal' },  'a variant state that follows the variant\'s normal state';
	is $document->effective_setting('button[primary].text.focused'), { spec => 'text_bright', origin => 'family' },  'a variant state the family sets';
	is $document->effective_setting('theme.extends'),                { spec => 'light',       origin => 'set' },     'extends';

	is Term::Fabulous::Theme::Document::parse_key('tabs[pill].line.style'), { section => 'slot', family => 'tabs', variant => 'pill', slot => 'line.style', state => 'normal' }, 'parse_key';
	is Term::Fabulous::Theme::Document::key_for( family => 'input', slot => 'border.color', state => 'invalid' ), 'input.border.color.invalid', 'key_for';
	like dies { $document->setting('button.nope') },  qr/the family button has no slot 'nope'/, 'an unknown slot dies';
	like dies { $document->setting('nope.text') },    qr/unknown family 'nope'/,                'an unknown family dies';
	like dies { $document->setting('palette.nope') }, qr/unknown token/,                        'an unknown token dies';
	like dies { $document->setting('whatever') },     qr/is not a setting key/,                 'a malformed key dies';
};

subtest 'errors carry their lines' => sub {
	my $broken = $Document->parse(qq{palette {\n\taccent "#fff"\n\ttext "x" foo=\n}\n});
	ok !$broken->is_valid,        'a syntax error';
	ok $broken->has_syntax_error, 'is a syntax error';
	is [ $broken->errors ], [ { line => 3, message => match(qr/\AKDL syntax: /) } ], 'on the line that holds it';
	is $broken->theme,      undef,                                                   'no theme';
	like dies { $broken->with_setting( 'palette.text', '#000000' ) }, qr/needs a document that is valid KDL; line 3/, 'it cannot be changed';

	my $wrong = $Document->parse(<<~'KDL');
		theme "a" extends="blue"
		palette {
			accent "#zz"
			nope "#fff"
		}
		button {
			border colour="x"
			focused { text "accent" }
			text.focused "accent"
			variant "primary" { text "nope" }
		}
		tabs { line style=Block }
		wat
		KDL
	is [ map { $_->{line} } $wrong->errors ], [ 1, 3, 4, 7, 9, 10, 12, 13 ], 'every mistake, sorted by line';
	is [ map { $_->{message} } $wrong->errors ],
		[
		"extends must be the name of a built-in theme (dark, light), got 'blue'",
		match(qr/\Apalette token accent must be a color, got '#zz'/),
		match(qr/\Apalette: unknown token 'nope' \(known: accent, /),
		match(qr/\Athe family button has no slot 'border\.colour' \(known: /),
		"button: the slot 'text.focused' is set twice",
		match(qr/\Avariant 'primary': |button\.text/),
		match(qr/tabs\.line\.style/),
		match(qr/\Aunknown top-level node 'wat'/),
		],
		'the messages name what is wrong';
	ok !$wrong->has_syntax_error, 'they are no syntax errors';
	like dies { Term::Fabulous::Theme->from_string( $wrong->text ) }, qr/Term::Fabulous::Theme/, 'and the theme module rejects the text too';
	ok $wrong->with_setting( 'palette.text', '#000000' )->setting('palette.text'), 'a document with such errors can still be changed';
	is [ map { $_->{message} } $Document->parse(qq{button {\n\tfocused { border style=Double }\n}\n})->errors ],
		["the slot button.border.style has no state 'focused' (it has the normal state only)"], 'a slot without states says so';
};

subtest 'changes in an empty document' => sub {
	my $document
		= $Document->parse('')
		->with_setting( 'theme.name',                           'fresh' )
		->with_setting( 'theme.extends',                        'light' )
		->with_setting( 'palette.accent',                       '#ff8800' )
		->with_setting( 'box.border.color',                     'accent' )
		->with_setting( 'box.border.style',                     'Double' )
		->with_setting( 'button.text.focused',                  'accent' )
		->with_setting( 'button.background',                    'surface' )
		->with_setting( 'button[primary].text',                 'text_bright' )
		->with_setting( 'button[primary].border.color.focused', '#ffffff' );
	is $document->text, <<~'KDL', 'blocks are made where they belong, slots grouped by their head';
		theme "fresh" extends="light"

		palette {
			accent "#ff8800"
		}

		box {
			border color="accent" style=Double
		}

		button {
			background "surface"
			focused {
				text "accent"
			}
			variant "primary" {
				text "text_bright"
				focused {
					border color="#ffffff"
				}
			}
		}
		KDL
	ok $document->is_valid, 'and valid';
	is $document->theme->look( 'button', 'border.color', 'focused', ['primary'] ), [ 255, 255, 255, 255 ], 'the theme has the values';

	my $smaller = $document->without_setting('button[primary].border.color.focused')->without_setting('box.border.style')->without_setting('box.border.color');
	is $smaller->text, <<~'KDL', 'removing the last setting of a block removes the block';
		theme "fresh" extends="light"

		palette {
			accent "#ff8800"
		}

		button {
			background "surface"
			focused {
				text "accent"
			}
			variant "primary" {
				text "text_bright"
			}
		}
		KDL
	is $smaller->without_variant( 'button', 'primary' )->setting_keys, 5,              'without_variant removes the variant block';
	is $smaller->without_setting('palette.text')->text,                $smaller->text, 'removing an unset key changes nothing';
	is $smaller->without_setting('theme.name')->text,                  $smaller->text =~ s/theme "fresh" extends/theme extends/r, 'the name goes, the theme node stays for extends';
	is $smaller->with_settings( [ [ 'theme.name', undef ], [ 'theme.extends', undef ] ] )->text, $smaller->text =~ s/\Atheme .*\n\n//r, 'and goes with extends';
};

subtest 'changes keep comments and layout' => sub {
	my $source = <<~'KDL';
		// Header comment.
		/* A block comment
		   over two lines. */

		theme "keep"   extends="dark"  // the base

		palette { accent "#010203"; text "#040506" }

		// Buttons.
		button {
			/-background "surface"
			border   style=Round
			text "text" // trailing


			focused { border color="accent" }
		}
		KDL
	my $document = $Document->parse($source);
	ok $document->is_valid, 'valid';

	my $changed = $document->with_setting( 'button.text', 'accent' );
	is changed_lines( $source, $changed->text ), [ [ "\ttext \"text\" // trailing", "\ttext \"accent\" // trailing" ] ], 'a trailing comment stays with its node';

	my $more = $changed->with_setting( 'button.border.color.focused', 'danger' );
	is changed_lines( $changed->text, $more->text ), [ [ "\tfocused { border color=\"accent\" }", "\tfocused { border color=\"danger\" }" ] ], 'a one-line block is written anew on its line';

	my $shared = $document->with_setting( 'palette.text', '#ffffff' );
	is changed_lines( $source, $shared->text ), [ [ 'palette { accent "#010203"; text "#040506" }', 'palette { accent "#010203"; text "#ffffff" }' ] ],
		'a block on one line is written anew on one line, everything else stays';

	my $removed = $document->without_setting('button.text');
	unlike $removed->text, qr/trailing/,                   'a removed node takes its trailing comment along';
	like $removed->text,   qr{/-background "surface"},     'a slashdashed node is kept as a comment';
	like $removed->text,   qr/style=Round\n\n\n\tfocused/, 'the blank lines before the next item stay';

	my $gone = $document->without_setting('button.border.style')->without_setting('button.text')->without_setting('button.border.color.focused');
	like $gone->text, qr{// Buttons\.\nbutton \{\n\t/-background "surface"\n\}\n\z},                     'a block left with a slashdashed node only stays, with it';
	unlike $gone->without_setting('palette.accent')->without_setting('palette.text')->text, qr/palette/, 'an empty block goes';
	is $document->with_setting( 'theme.name', 'other' )->text =~ /\n(theme .*)\n/ ? $1 : undef, 'theme "other" extends="dark" // the base', 'a changed head is written anew with its comment';
};

subtest 'nodes that share lines' => sub {
	my $two = $Document->parse(qq{button {\n\ttext "danger"; background "accent"\n}\n});
	is $two->with_setting( 'button.background', 'success' )->text, qq{button {\n\ttext "danger"\n\tbackground "success"\n}\n}, 'a node on a shared line is written anew, its neighbor once';
	is $two->without_setting('button.background')->text,           qq{button {\n\ttext "danger"\n}\n},                         'and removed from it';

	my $top = $Document->parse(qq{palette { accent "#ffffff" }; button { text "danger" }\n});
	is $top->with_setting( 'button.text', 'accent' )->text, qq{palette { accent "#ffffff" }\nbutton { text "accent" }\n}, 'blocks on one line are written one per line';

	my $closing = $Document->parse(qq{button {\n\ttext "danger"\n} // end of button\n});
	is $closing->with_setting( 'button.background', 'accent' )->text, qq{button {\n\ttext "danger"\n\tbackground "accent"\n} // end of button\n}, 'a comment after a closing brace stays there';
	is $closing->with_setting( 'button.background', 'accent' )->without_setting('button.text')->text, qq{button {\n\tbackground "accent"\n} // end of button\n}, 'also when the block is written anew';

	my $last = $Document->parse(qq{button {\n\ttext "danger" }\n});
	is $last->with_setting( 'button.background', 'accent' )->text, qq{button {\n\ttext "danger"\n\tbackground "accent"\n}\n}, 'a node on the closing line';

	my $slashed = $Document->parse(qq{button {\n\tborder /-style=Double color="accent"\n\t/-text "x"\n}\n});
	is $slashed->with_setting( 'button.border.style', 'Round' )->text, qq{button {\n\tborder color="accent" style=Round /-style=Double\n\t/-text "x"\n}\n}, 'slashdashed properties and nodes are kept';
	my $inline = $Document->parse(qq{palette { accent "#ffffff"; /* keep */ text "#000000" }\n});
	is $inline->with_setting( 'palette.accent', '#ff0000' )->text, qq{palette { accent "#ff0000"; /* keep */ text "#000000" }\n}, 'a one-line block keeps its block comments';
	ok $inline->with_setting( 'palette.accent', '#ff0000' )->is_valid, 'and stays valid';

	my $headed = $Document->parse(qq{button { /* c */ text "accent" }\n});
	my $twice  = $headed->with_setting( 'button.text', 'success' )->with_setting( 'button.text', 'danger' );
	is( ( () = $twice->text =~ m{/\* c \*/}g ), 1, 'a comment in a one-line block is written once, edit after edit' );

	my $nested = $Document->parse(qq{button { focused {\n\t\ttext "accent"\n\t}\n}\n});
	ok $nested->with_setting( 'button.background.focused', 'accent' )->is_valid, 'a block that shares its head line with its parent';
	my $sibling = $Document->parse(qq{button {\n\ttext "accent"; focused {\n\t\ttext "danger"\n\t}\n}\n});
	ok $sibling->with_setting( 'button.background.focused', 'accent' )->is_valid, 'or with a sibling';

	my $multi = $Document->parse(qq{button {\n\ttext "accent"\n} /* multi\nline */\ndivider {\n\tline style=Double\n}\n});
	like $multi->with_setting( 'button.background', 'danger' )->text, qr{\} /\* multi\nline \*/\n}, 'a comment of two lines after a closing brace stays there';
};

subtest 'line ends, indentation and KDL 1' => sub {
	my $crlf = $Document->parse("palette {\r\n    accent \"#000000\"\r\n}\r\n");
	is $crlf->with_setting( 'palette.text', '#ffffff' )->text, "palette {\r\n    accent \"#000000\"\r\n    text \"#ffffff\"\r\n}\r\n", 'CRLF line ends and four-space indentation are kept';

	my $legacy = $Document->parse(qq{tabs {\n\tline style="Round"\n\ttext null\n}\n});
	is $legacy->kdl_version, 1, 'a KDL 1 file';
	ok $legacy->is_valid, 'is valid';
	is $legacy->with_setting( 'tabs.line.style', 'Double' )->text, qq{tabs {\n\tline style="Double"\n\ttext null\n}\n}, 'and is written as KDL 1';

	my $unicode = $Document->parse(qq{theme "Grüße"\n});
	is $unicode->with_setting( 'theme.extends', 'light' )->text,                 qq{theme "Grüße" extends="light"\n}, 'characters survive';
	is $Document->parse('')->with_setting( 'theme.name', qq{say "hi"\n} )->text, qq{theme "say \\"hi\\"\\n"\n},       'strings are escaped';
};

subtest 'values are checked before they are written' => sub {
	my $document = $Document->parse('');
	like dies { $document->with_setting( 'palette.accent',  'accent' ) },    qr/palette token accent must be a color/,                'a token takes a color only';
	like dies { $document->with_setting( 'tabs.line.style', 'none' ) },      qr/tabs\.line\.style cannot be 'none'/,                  'a required slot';
	like dies { $document->with_setting( 'box.background',  'reverse' ) },   qr/cannot be 'reverse'/,                                 'reverse elsewhere';
	like dies { $document->with_setting( 'theme.extends',   'blue' ) },      qr/theme\.extends must be the name of a built-in theme/, 'an unknown base';
	like dies { $document->with_setting( 'box.background',  undef ) },       qr/use without_setting/,                                 'undef';
	like dies { $document->with_setting( 'box.background',  [ 1, 2, 3 ] ) }, qr/needs a string value/,                                'a reference';
	like dies { $document->with_settings( [ ['box.background'] ] ) }, qr/a change must be \[ key, value \]/, 'a malformed change';
	is $document->with_setting( 'button.background.pressed', 'reverse' )->setting('button.background.pressed'), 'reverse',                           'reverse where it is allowed';
	is $document->with_setting( 'box.background',            'none' )->text,                                    qq{box {\n\tbackground "none"\n}\n}, 'none';
};

subtest 'border.enabled is written and read as a KDL boolean' => sub {
	my $document = $Document->parse(qq{text_input {\n\tborder style=Solid\n}\n})->with_setting( 'text_input.border.enabled', 1 );
	is $document->text,                                          qq{text_input {\n\tborder style=Solid enabled=#true\n}\n}, 'true joins the border node as #true';
	is $document->setting('text_input.border.enabled'),          'true',                                                    'and reads as true';
	is $document->theme->look( 'text_input', 'border.enabled' ), 1,                                                         'the theme has it';
	is $Document->parse(qq{button {\n\tborder enabled=true\n}\n})->with_setting( 'button.border.enabled', 'false' )->text, qq{button {\n\tborder enabled=false\n}\n},         'a KDL 1 file gets false';
	is [ map { $_->{message} } $Document->parse(qq{button {\n\tborder enabled="true"\n}\n})->errors ],                     ['button.border.enabled must be #true or #false'], 'a string is an error';
	like dies { $document->with_setting( 'text_input.border.enabled', 'yes' ) }, qr/text_input\.border\.enabled must be true, false, 1 or 0, got 'yes'/, 'another value dies';
};

subtest 'files' => sub {
	my $directory = tempdir( CLEANUP => 1 );
	my $path      = "$directory/theme.kdl";
	my $document  = $Document->parse(qq{theme "Grüße" extends="dark"\n});
	ref_is $document->write_file($path), $document, 'write_file returns the document';
	is $Document->read_file($path)->text, $document->text, 'what is read back is what was written, as UTF-8';
	chmod 0600, $path;
	$document->with_setting( 'theme.extends', 'light' )->write_file($path);
SKIP: {
		skip 'Windows has no POSIX permissions', 1 if $^O eq 'MSWin32';
		is( ( stat $path )[2] & oct(777), oct(600), 'an existing file keeps its permissions' );
	}
	is [ glob("$directory/*.tmp-*") ], [], 'no temporary file is left';

	open my $handle, '>:raw', "$directory/latin1.kdl" or die;
	print {$handle} "theme \"Gr\xFC\xDFe\"\n";
	close $handle;
	like dies { $Document->read_file("$directory/latin1.kdl") }, qr/is not UTF-8 text/, 'a file in another encoding dies';
	like dies { $Document->read_file("$directory/none.kdl") },   qr/cannot open/,       'a missing file dies';

	symlink "$directory/theme.kdl", "$directory/link.kdl" or die "symlink: $!";
	$document->with_setting( 'theme.extends', 'dark' )->write_file("$directory/link.kdl");
	ok -l "$directory/link.kdl", 'a symbolic link stays a link';
	like $Document->read_file("$directory/theme.kdl")->text, qr/extends="dark"/, 'and its target is written';
	chmod 0444, "$directory/theme.kdl";
	like dies { $document->write_file("$directory/theme.kdl") }, qr/it is read-only/, 'a read-only file is not replaced';
	chmod 0644, "$directory/theme.kdl";

	symlink "missing/theme.kdl", "$directory/dangling.kdl" or die "symlink: $!";
	mkdir "$directory/missing";
	$document->write_file("$directory/dangling.kdl");
	ok -l "$directory/dangling.kdl" && -f "$directory/missing/theme.kdl", 'a link to a file not yet there gets the file made';
	like dies { $Document->parse(undef) }, qr/must be a character string/, 'undef text dies';
};

done_testing;
