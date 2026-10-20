use v5.32;
use warnings;
use utf8;

use Test2::V0;
use Encode ();

use Term::Fabulous::Unicode qw(sanitize_text grapheme_clusters cluster_columns string_columns fit_columns ELLIPSIS);

subtest 'sanitize_text' => sub {
	is sanitize_text("a\tb"),                 'a b',                  'TAB becomes a space';
	is sanitize_text("\e]0;x\a"),             "\x{FFFD}]0;x\x{FFFD}", 'ESC and BEL become U+FFFD';
	is sanitize_text("\x00\x1F\x7F\x85\x9F"), "\x{FFFD}" x 5,         'C0, DEL and C1 become U+FFFD';
	is sanitize_text("\x{A0}\x{3042}"),       "\x{A0}\x{3042}",       'printable text is untouched';
};

subtest 'sanitize_text rejects malformed UTF-8' => sub {
	my $malformed = "\xC3A";
	Encode::_utf8_on($malformed);
	like dies { sanitize_text($malformed) },     qr/\ATerm::Fabulous::Unicode: sanitize_text needs well-formed UTF-8/, 'sanitize_text dies with its own message';
	like dies { grapheme_clusters($malformed) }, qr/\ATerm::Fabulous::Unicode: sanitize_text needs well-formed UTF-8/, 'so do the functions built on it';
};

subtest 'widths follow the termbox2 rule' => sub {
	is cluster_columns('a'),                  1,                   'ASCII';
	is cluster_columns("\x{4E00}"),           2,                   'CJK ideograph';
	is cluster_columns("\x{2764}\x{FE0F}"),   2,                   'VS16 asks for emoji presentation';
	is cluster_columns("\x{2764}\x{FE0E}"),   1,                   'VS15 asks for text presentation';
	is cluster_columns("\x{1F1E9}\x{1F1EA}"), 2,                   'two regional indicators make one flag';
	is cluster_columns("e\x{301}"),           1,                   'combining sequence';
	is cluster_columns("\x{200B}"),           1,                   'zero-width cluster still occupies a cell';
	is cluster_columns("\x{FFFD}"),           1,                   'replacement character';
	is [ grapheme_clusters("a\e") ],          [ 'a', "\x{FFFD}" ], 'clusters are sanitized';
	is string_columns("ab\tc"),               4,                   'string_columns sanitizes before measuring';
	is string_columns(''),                    0,                   'empty string';
	like dies { cluster_columns('') }, qr/non-empty cluster/, 'empty cluster dies';
};

subtest 'results are cached' => sub {
	my @first = grapheme_clusters("a\x{1F1E9}\x{1F1EA}");
	push @first, 'x';
	is [ grapheme_clusters("a\x{1F1E9}\x{1F1EA}") ], [ 'a', "\x{1F1E9}\x{1F1EA}" ], 'a cached cluster list is returned as a copy';
	is string_columns("a\x{1F1E9}\x{1F1EA}"),        3,                             'first measurement';
	is string_columns("a\x{1F1E9}\x{1F1EA}"),        3,                             'the cached measurement';
};

subtest 'fit_columns cuts to the room' => sub {
	is fit_columns( 'short', 5 ),                                          'short',        'a text that fits is unchanged';
	is fit_columns( 'Hello world', 5 ),                                    "Hell\x{2026}", 'cut at the end, an ellipsis by default';
	is fit_columns( 'Hello world', 5, mark => '~' ),                       'Hell~',        'its own mark';
	is fit_columns( 'Hello', 0 ),                                          '',             'no room';
	is fit_columns( 'Hello', -3 ),                                         '',             'less than no room';
	is fit_columns( 'Hello', 1 ),                                          ELLIPSIS,       'room for the mark alone';
	is fit_columns( '/home/ada/notes', 9, mark => '...', cut => 'start' ), '.../notes',    'cut at the start keeps the end';
};

subtest 'fit_columns keeps clusters whole' => sub {
	is fit_columns( "\x{65E5}\x{672C}\x{8A9E}", 4 ),                   "\x{65E5}\x{2026}",         'a wide character that does not fit leaves its column empty';
	is string_columns( fit_columns( "\x{65E5}\x{672C}\x{8A9E}", 4 ) ), 3,                          'so the result is narrower than the room';
	is fit_columns( "e\x{301}e\x{301}e\x{301}x", 3 ),                  "e\x{301}e\x{301}\x{2026}", 'combining marks stay with their letter';
	is fit_columns( "ab\x{2764}\x{FE0F}cd", 4 ),                       "ab\x{2026}",               'a variation selector stays with its emoji';
	my ( $man, $woman ) = ( "\x{1F468}\x{200D}", "\x{1F469}\x{200D}" );
	is [ grapheme_clusters("$man${woman}x") ],                       [ $man, $woman, 'x' ],      'Unicode::GCString keeps a zero-width joiner with the emoji before it';
	is fit_columns( "ab$man${woman}cd", 5 ),                         "ab$man\x{2026}",           'so a cut in a ZWJ sequence keeps each joiner with its emoji';
	is fit_columns( "ab$man${woman}cd", 4, cut => 'start' ),         "\x{2026}cd",               'also from the start';
	is fit_columns( "\x{3042}\x{3044}\x{3046}", 5, cut => 'start' ), "\x{2026}\x{3044}\x{3046}", 'wide characters from the start';
};

subtest 'fit_columns cuts a mark wider than the room' => sub {
	is fit_columns( 'Hello', 2, mark => '...' ),                 '..',  'at the end';
	is fit_columns( 'Hello', 1, mark => '...', cut => 'start' ), '.',   'at the start';
	is fit_columns( 'Hello', 3, mark => '...' ),                 '...', 'a mark as wide as the room';
	is fit_columns( 'Hello', 1, mark => "\x{3042}" ),            '',    'a wide mark into one column';
};

subtest 'fit_columns checks its arguments' => sub {
	like dies { fit_columns( undef, 3 ) },                qr/\ATerm::Fabulous::Unicode: fit_columns needs a text, got undef/,                    'text';
	like dies { fit_columns( 'a', 1.5 ) },                qr/\ATerm::Fabulous::Unicode: fit_columns needs a whole number of columns, got '1.5'/, 'columns';
	like dies { fit_columns( 'a', [] ) },                 qr/fit_columns needs a whole number of columns, got an ARRAY reference/,               'columns reference';
	like dies { fit_columns( 'a', 1, mark => {} ) },      qr/\ATerm::Fabulous::Unicode: fit_columns mark must be a text, got a HASH reference/,  'mark';
	like dies { fit_columns( 'a', 1, cut => 'middle' ) }, qr/\ATerm::Fabulous::Unicode: fit_columns cut must be 'end' or 'start', got 'middle'/, 'cut';
	like dies { fit_columns( 'a', 1, width => 2 ) },      qr/\ATerm::Fabulous::Unicode: fit_columns does not take width \(known: cut mark\)/,    'unknown option';
};

done_testing;
