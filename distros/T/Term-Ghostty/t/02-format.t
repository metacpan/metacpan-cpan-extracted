use strict;
use warnings;
use utf8;
use Test::More;
use Term::Ghostty;

my $term = Term::Ghostty->new(cols => 80, rows => 24);

$term->feed("Line 1: \e[1mBold\e[0m text\r\n");
$term->feed("Line 2: \e[31mRed\e[0m and \e[32mGreen\e[0m\r\n");
$term->feed("Line 3: Unicode 🚀 привет\r\n");

my $plain = $term->get_text(trim => 1);
like($plain, qr/Line 1: Bold text/, 'plain text has bold text stripped of ansi');
like($plain, qr/Line 2: Red and Green/, 'plain text has colored text stripped of ansi');
like($plain, qr/Line 3: Unicode 🚀 привет/, 'plain text preserves characters');
ok(utf8::is_utf8($plain), 'plain text is a character string');

my $vt = $term->get_vt(trim => 1);
like($vt, qr/\e\[1mBold/, 'VT format preserves ANSI bold escape code');
like($vt, qr/\e\[31mRed|\e\[38;5;1mRed/, 'VT format preserves ANSI red escape code');

my $html = $term->get_html(trim => 1);
like($html, qr/<div/, 'HTML format produces HTML tags');
like($html, qr/Red/, 'HTML format includes text');

is($term->get_text(format => 'html'), $plain, 'get_text ignores a format option');

$term->feed("<script>&\"'");
like($term->get_html, qr/&lt;script&gt;&amp;/, 'HTML output escapes markup');

$term->write("\e[");
my ($consumed, $ground) = $term->write_until_ground("0mTrailingData");
is($consumed, 2, 'consumed exactly 2 bytes ("0m") to complete escape sequence');
ok($ground, 'reached ground state');
($consumed, $ground) = $term->write_until_ground("abc");
is($consumed, 0, 'already at ground: nothing consumed');
ok($ground, 'still at ground');
$term->write("\e[1;");
($consumed, $ground) = $term->write_until_ground("3");
is($consumed, 1, 'all input consumed');
ok(!$ground, 'ground not reached mid-sequence');
is(scalar $term->write_until_ground("m"), 1, 'scalar context returns the byte count');

my $sb = Term::Ghostty->new(cols => 10, rows => 5);
$sb->feed("L$_\r\n") for 1 .. 8;
$sb->feed("\e[2J\e[HA\r\nB");
is($sb->get_text, "A\nB", 'default output is the visible screen only');
like($sb->get_text(scrollback => 1), qr/^L1\n.*L4\n.*A\nB\z/s, 'scrollback => 1 includes history');
unlike($sb->get_text, qr/L4/, 'history not in the visible screen');

my $alt = Term::Ghostty->new(cols => 10, rows => 3);
$alt->feed("main\r\n\e[?1049hALT");
is($alt->get_text, "\nALT", 'alternate screen is formatted while active');

my $cur = Term::Ghostty->new(cols => 20, rows => 5);
$cur->feed("ab\e[3;5H");
like($cur->format(format => 'vt', cursor => 1), qr/\e\[3;5H\z/, 'cursor => 1 emits the cursor position');
unlike($cur->format(format => 'vt'), qr/\e\[3;5H/, 'no cursor position by default');
$cur->feed("\e[2;4r");
like($cur->format(format => 'vt', scrolling_region => 1), qr/\e\[2;4r/, 'scrolling_region => 1');

my $wrap = Term::Ghostty->new(cols => 5, rows => 3);
$wrap->feed("abcdefgh");
is($wrap->get_text, "abcde\nfgh", 'soft-wrapped line split by default');
is($wrap->get_text(unwrap => 1), "abcdefgh", 'unwrap => 1 joins soft-wrapped lines');

my $pad = Term::Ghostty->new(cols => 10, rows => 2);
$pad->feed("x   \r\ny");
is($pad->get_text, "x\ny", 'trailing spaces trimmed by default');
is($pad->get_text(trim => 0), "x   \ny", 'trim => 0 keeps written trailing spaces');

my $style = Term::Ghostty->new(cols => 20, rows => 2);
$style->feed("a\e[1;31m");
like($style->format(format => 'vt', style => 1), qr/\e\[[0-9;]*1[;m].*\z/s, 'style => 1 emits the pending SGR state');
unlike($style->format(format => 'vt'), qr/\e\[[0-9;]*m\z/, 'no pending SGR state by default');

my $pal = Term::Ghostty->new(cols => 20, rows => 2);
$pal->feed("\e[31mred");
like($pal->get_html, qr/--vt-palette-1:/, 'html defines the palette variables by default');
unlike($pal->get_html(palette => 0), qr/<style>/, 'palette => 0 omits them');
unlike($pal->get_vt, qr/\e\]4;/, 'vt does not emit the palette by default');

my $link = Term::Ghostty->new(cols => 80, rows => 2);
$link->feed("\e]8;;javascript:alert(1)\e\\bad\e]8;;\e\\ \e]8;; JavaScript:x\e\\bad2\e]8;;\e\\ "
          . "\e]8;;https://example.com/?a=1&b=2\e\\good\e]8;;\e\\ \e]8;;MAILTO:me\@x\e\\mail\e]8;;\e\\");
my $lh = $link->get_html;
unlike($lh, qr/javascript/i, 'javascript: links are dropped');
like($lh, qr{<a>bad</a> <a>bad2</a>}, 'unsafe links keep their text');
like($lh, qr{<a href="https://example.com/\?a=1&amp;b=2">good</a>}, 'https links kept');
like($lh, qr{<a href="MAILTO:me\@x">mail</a>}, 'scheme match is case-insensitive');

ok(!eval { $term->format(format => 'pdf'); 1 }, 'invalid format croaks');
like($@, qr/format must be/, 'invalid format message');
ok(!eval { $term->format(bogus => 1); 1 }, 'unknown option croaks');
ok(!eval { $term->format('trim'); 1 }, 'odd arguments croak');

done_testing;
