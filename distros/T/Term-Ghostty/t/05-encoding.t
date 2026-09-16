use strict;
use warnings;
use utf8;
use Test::More;
use Term::Ghostty;

sub screen {
    my $t = Term::Ghostty->new(cols => 40, rows => 3);
    $t->feed($_) for @_;
    return $t->get_text;
}

is(screen("caf\xc3\xa9"), "café", 'UTF-8 bytes are decoded');
is(screen("caf\xc3", "\xa9 ok"), "café ok", 'a character split across writes');
is(screen("\xf0\x9f", "\x9a\x80"), "🚀", 'a 4-byte character split across writes');
is(screen("café 🚀"), "café 🚀", 'character strings are encoded as UTF-8');
my $bytes = "caf\xc3\xa9";
screen($bytes);
ok(!utf8::is_utf8($bytes), 'feed does not upgrade the caller string');
is(screen("a\xffb"), "a\x{FFFD}b", 'invalid UTF-8 input becomes U+FFFD');

my $t = Term::Ghostty->new;
$t->set_title("Café \x{263A}");
is($t->title, "Café \x{263A}", 'title round-trips characters');
my $latin1 = "caf\xe9";
$t->set_title($latin1);
is($t->title, "café", 'a Latin-1 string title is treated as characters');
ok(!utf8::is_utf8($latin1), 'set_title does not upgrade the caller string');
ok(utf8::is_utf8($t->title), 'title is a character string');

$t->feed("\e]2;\xd0\xbf\xd1\x80\xd0\xb8\xd0\xb2\xd0\xb5\xd1\x82\e\\");
is($t->title, "привет", 'OSC 2 title bytes are decoded');

$t->feed("\e]7;file:///tmp/\xff\xfeok\e\\");
is($t->pwd, "file:///tmp/\x{FFFD}\x{FFFD}ok", 'malformed UTF-8 in pwd becomes U+FFFD');
ok(utf8::valid($t->pwd), 'pwd is valid');

$t->feed("\e]2;a" . ("é" x 600) . "\e\\");
ok(utf8::valid($t->title), 'title truncated mid-character by the library is still valid');
like($t->title, qr/\x{FFFD}\z/, 'the cut character becomes U+FFFD');

done_testing;
