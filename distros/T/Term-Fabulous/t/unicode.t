use v5.32;
use warnings;
use utf8;

use Test2::V0;
use Encode ();

use Term::Fabulous::Unicode qw(sanitize_text grapheme_clusters cluster_columns string_columns);

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

done_testing;
