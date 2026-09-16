use strict;
use warnings;
use Test::More;
use Term::Ghostty;

my $term = Term::Ghostty->new(cols => 80, rows => 24);
isa_ok($term, 'Term::Ghostty');

is($term->cols, 80, 'cols is 80');
is($term->rows, 24, 'rows is 24');

my ($cx, $cy) = $term->cursor_pos;
is($cx, 0, 'initial cursor x is 0');
is($cy, 0, 'initial cursor y is 0');
is($term->cursor_x, 0, 'cursor_x is 0');
is($term->cursor_y, 0, 'cursor_y is 0');
is_deeply(scalar $term->cursor_pos, [0, 0], 'cursor_pos in scalar context');

ok($term->cursor_visible, 'cursor is initially visible');
ok(!$term->cursor_pending_wrap, 'no pending wrap');

$term->write("Hello, Ghostty!\r\n");
($cx, $cy) = $term->cursor_pos;
is($cx, 0, 'cursor x after newline is 0');
is($cy, 1, 'cursor y after newline is 1');
like($term->get_text, qr/^Hello, Ghostty!/, 'screen text contains written string');

$term->resize(100, 30);
is($term->cols, 100, 'cols is now 100');
is($term->rows, 30, 'rows is now 30');

$term->reset;
is_deeply([$term->cursor_pos], [0, 0], 'cursor home after reset');

$term->set_title("Terminal Title");
is($term->title, "Terminal Title", 'manual title set');
$term->set_title(undef);
is($term->title, '', 'undef clears the title');
$term->set_pwd("/tmp/my_dir");
is($term->pwd, "/tmp/my_dir", 'manual pwd set');

my $init = Term::Ghostty->new(title => 'first', pwd => 'file:///x');
is($init->title, 'first', 'title from new');
is($init->pwd, 'file:///x', 'pwd from new');

is(Term::Ghostty->new->cols, 80, 'default cols');
is(Term::Ghostty->new->rows, 24, 'default rows');
is(Term::Ghostty->new(cols => 65535, rows => 1)->cols, 65535, 'largest cols accepted');
is(ref($term->new(cols => 5)), 'Term::Ghostty', 'new on an instance uses its class');

for my $bad ([cols => 0], [cols => -1], [cols => 65536], [cols => 65616], [rows => 'abc'],
             [cell_width_px => -1], [cell_height_px => 2**32]) {
    no warnings 'numeric';
    ok(!eval { Term::Ghostty->new(@$bad); 1 }, "new(@$bad) croaks");
    like($@, qr/must be between/, "new(@$bad) error message");
}
ok(!eval { $term->resize(65546, 24); 1 }, 'resize beyond 65535 croaks');
is($term->cols, 100, 'failed resize leaves size unchanged');
ok(!eval { $term->resize(0, 24); 1 }, 'resize to zero croaks');

ok(!eval { Term::Ghostty->new('cols'); 1 }, 'odd arguments croak');
like($@, qr/odd number/, 'odd arguments message');
ok(!eval { Term::Ghostty->new(colz => 80); 1 }, 'unknown option croaks');
like($@, qr/unknown option 'colz'/, 'unknown option message');
for my $cb ('main::nope', {}, [], \1) {
    ok(!eval { Term::Ghostty->new(on_bell => $cb); 1 }, 'non-code callback croaks in new');
    ok(!eval { $term->on_bell($cb); 1 }, 'non-code callback croaks in setter');
}
like($@, qr/on_bell must be a code reference/, 'callback type message');
ok(!eval { $term->on_bell(sub {}, 1); 1 }, 'setter with two arguments croaks');

is($term->active_screen, 'primary', 'primary screen');
$term->feed("\e[?1049h");
is($term->active_screen, 'alternate', 'alternate screen after 1049h');
ok($term->mode(1049), 'mode 1049 set');
$term->feed("\e[?1049l");
is($term->active_screen, 'primary', 'back to primary');

ok($term->mode(7), 'wraparound (DEC 7) on by default');
ok(!$term->mode(4, 1), 'insert mode (ANSI 4) off by default');
$term->feed("\e[4h");
ok($term->mode(4, 1), 'insert mode on after CSI 4 h');
is($term->mode(31000), undef, 'unknown mode is undef');
ok(!eval { $term->mode(40000); 1 }, 'mode out of range croaks');

ok(!$term->mouse_tracking, 'no mouse tracking');
$term->feed("\e[?1000h");
ok($term->mouse_tracking, 'mouse tracking after 1000h');

my $sb = Term::Ghostty->new(cols => 20, rows => 5);
is($sb->scrollback_rows, 0, 'no scrollback yet');
$sb->feed("line $_\r\n") for 1 .. 50;
is($sb->scrollback_rows, 46, 'scrollback rows after 50 lines');

my %kept;
for my $max (undef, 5000, 0) {
    my $t = Term::Ghostty->new(cols => 80, rows => 24, defined $max ? (max_scrollback => $max) : ());
    $t->feed("line $_\r\n") for 1 .. 3000;
    $kept{$max // 'default'} = $t->scrollback_rows;
    if (defined $max && $max) {
        like($t->get_text(scrollback => 1), qr/\Aline 1\n/, 'max_scrollback keeps the start of the history');
        $t->reset;
        $t->feed("line $_\r\n") for 1 .. 3000;
        is($t->scrollback_rows, $kept{$max}, 'max_scrollback survives reset');
    }
}
ok($kept{default} > 0 && $kept{default} < 2000, "default scrollback is limited ($kept{default} rows)");
is($kept{5000}, 2977, 'max_scrollback => 5000 keeps all 2977 rows');
is($kept{0}, 0, 'max_scrollback => 0 disables the scrollback');
ok(!eval { Term::Ghostty->new(max_scrollback => -1); 1 }, 'negative max_scrollback croaks');
{
    my $t = Term::Ghostty->new(cols => 80, rows => 24, max_scrollback => undef);
    $t->feed("line $_\r\n") for 1 .. 3000;
    is($t->scrollback_rows, $kept{default}, 'max_scrollback => undef keeps the default');
    my $u = Term::Ghostty->new(cols => 80, rows => 24, max_scrollback => 5000, max_scrollback => undef);
    $u->feed("line $_\r\n") for 1 .. 3000;
    is($u->scrollback_rows, $kept{default}, 'a later max_scrollback => undef wins');
}

{
    my @reports;
    my $t = Term::Ghostty->new(cell_width_px => 7, cell_height_px => 9, on_pty_write => sub { push @reports, $_[1] });
    "title-from-capture" =~ /^(.*)$/;
    $t->set_title($1);
    is($t->title, 'title-from-capture', 'set_title with a capture variable');
    "file:///from/capture" =~ /^(.*)$/;
    $t->set_pwd($1);
    is($t->pwd, 'file:///from/capture', 'set_pwd with a capture variable');
    $t->feed("\e[?2048h");
    @reports = ();
    "100x30 10x20" =~ /^(\d+)x(\d+) (\d+)x(\d+)$/;
    $t->resize($1, $2, $3, $4);
    is_deeply(\@reports, ["\e[48;30;100;600;1000t"], 'resize with capture variables');
    "new-title" =~ /(.*)/;
    is(Term::Ghostty->new(title => $1)->title, 'new-title', 'new with a capture variable title');
}

done_testing;
