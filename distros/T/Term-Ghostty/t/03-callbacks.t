use strict;
use warnings;
use Test::More;
use Scalar::Util ();
use Term::Ghostty;

my (@pty_writes, @titles, @pwds, @bell_args);
my $bell_count = 0;

my $term = Term::Ghostty->new(
    cols             => 80,
    rows             => 24,
    on_pty_write     => sub { push @pty_writes, $_[1] },
    on_title_changed => sub { push @titles, $_[1] },
    on_bell          => sub { $bell_count++; @bell_args = @_ },
    on_pwd_changed   => sub { push @pwds, $_[1] },
);

$term->feed("\a");
is($bell_count, 1, 'on_bell invoked on BEL character');
{
    my $context = 'unset';
    Term::Ghostty->new(on_bell => sub { $context = wantarray })->feed("\a");
    is($context, undef, 'callbacks run in void context');
}
is(scalar @bell_args, 1, 'on_bell gets one argument');
is(ref $bell_args[0], 'Term::Ghostty', 'callback gets the terminal');
is(Scalar::Util::refaddr($bell_args[0]), Scalar::Util::refaddr($term), 'callback gets the same object');

$term->feed("\e]2;Window Title from OSC\e\\");
is_deeply(\@titles, ['Window Title from OSC'], 'on_title_changed invoked with the title');
is($term->title, 'Window Title from OSC', 'term->title matches callback title');
$term->set_title('manual');
is(scalar @titles, 1, 'set_title does not fire on_title_changed');

$term->feed("\e[?7\$p");
is(scalar(@pty_writes), 1, 'on_pty_write invoked in response to DECRQM query');
like($pty_writes[0], qr/^\e\[\?7;[12]\$y/, 'received expected DECRQM response sequence');
ok(!utf8::is_utf8($pty_writes[0]), 'pty data is a byte string');

$term->feed("\e]7;file://localhost/home/user/project\e\\");
is_deeply(\@pwds, ['file://localhost/home/user/project'], 'on_pwd_changed gets the raw OSC 7 URL');
is($term->pwd, 'file://localhost/home/user/project', 'pwd is the raw URL');

sub replies {
    my ($t, $in) = @_;
    @pty_writes = ();
    $t->feed($in);
    return join '', @pty_writes;
}
is(replies($term, "\e[c"), "\e[?62;22c", 'DA1 answered');
is(replies($term, "\e[>c"), "\e[>1;0;0c", 'DA2 answered');
is(replies($term, "\e[18t"), "\e[8;24;80t", 'text area size (CSI 18 t) answered');
is(replies($term, "\e[6n"), "\e[1;1R", 'cursor position report answered');

my @reports;
my $px = Term::Ghostty->new(cols => 80, rows => 24, cell_width_px => 10, cell_height_px => 20,
                            on_pty_write => sub { push @reports, $_[1] });
$px->feed("\e[14t");
is($reports[-1], "\e[4;480;800t", 'pixel size (CSI 14 t) uses cell size from new');
$px->feed("\e[?2048h");
@reports = ();
$px->resize(100, 30);
is_deeply(\@reports, ["\e[48;30;100;600;1000t"], 'resize fires the in-band size report, keeping cell size');
@reports = ();
$px->resize(100, 30, 8, 16);
is_deeply(\@reports, ["\e[48;30;100;480;800t"], 'resize with new cell size');

my $dynamic_bell = 0;
my $old_bell_cb = $term->on_bell(sub { $dynamic_bell++ });
is(ref($old_bell_cb), 'CODE', 'on_bell returned previous coderef');
is(ref($term->on_bell), 'CODE', 'on_bell without arguments is a getter');
$term->feed("\a");
is($dynamic_bell, 1, 'new bell callback fired');
is($bell_count, 1, 'old bell callback was not fired');
$term->on_bell(undef);
is($term->on_bell, undef, 'getter returns undef after clearing');
$term->feed("\a");
is($dynamic_bell, 1, 'no callback fired after clearing with undef');
$term->on_pwd_changed(undef);
$term->feed("\e]7;file:///elsewhere\e\\");
is(scalar @pwds, 1, 'cleared on_pwd_changed does not fire');

{
    my $t = Term::Ghostty->new(on_bell => sub { die "boom\n" });
    ok(!eval { $t->feed("A\aBCD"); 1 }, 'exception from a callback propagates');
    is($@, "boom\n", 'with its message');
    is($t->get_text, 'ABCD', 'input after the failing callback is still processed');
    $t->feed("E");
    is($t->get_text, 'ABCDE', 'terminal usable afterwards');

    my $n = 0;
    $t->on_bell(sub { $n++; die "first\n" if $n == 1; die "second\n" });
    ok(!eval { $t->feed("\a\a\a"); 1 }, 'multiple failing callbacks');
    is($@, "first\n", 'the first exception wins');
    is($n, 1, 'callbacks are skipped after one dies');

    my $obj = bless {}, 'My::Error';
    $t->on_bell(sub { die $obj });
    eval { $t->feed("\a") };
    is($@, $obj, 'exception objects propagate');

    $t->on_bell(sub { local $SIG{__WARN__} = sub { die "from warn\n" }; warn "x" });
    ok(!eval { $t->feed("\a"); 1 }, 'die from a __WARN__ handler in a callback');
    is($@, "from warn\n", 'is caught and rethrown');

    eval { die "outer\n" };
    $t->on_bell(sub { 1 });
    $t->feed("\a");
    is($@, "outer\n", '$@ is preserved across a successful callback');
}

{
    my @errs;
    my $t = Term::Ghostty->new;
    $t->on_bell(sub {
        my $s = shift;
        for my $call ([feed => 'x'], [write => 'x'], [write_until_ground => 'x'], [resize => 10, 10],
                      ['reset'], [set_title => 'x'], [set_pwd => 'x']) {
            my ($m, @a) = @$call;
            eval { $s->$m(@a) };
            push @errs, $@ =~ /cannot be called from inside a callback/ ? $m : "$m: $@";
        }
        push @errs, 'read:' . $s->cols . ',' . scalar(@{ $s->cursor_pos }) . ',' . length($s->get_text);
    });
    $t->feed("ab\a");
    is_deeply(\@errs, [qw(feed write write_until_ground resize reset set_title set_pwd), 'read:80,2,2'],
              'mutators croak inside callbacks, readers work');
    $t->feed("cd");
    is($t->get_text, 'abcd', 'no reentrant write happened');
}

{
    my $calls = 0;
    my $t = Term::Ghostty->new;
    my $count = 0;
    $t->on_bell(sub { $calls++; $_[0]->on_bell(undef); my @junk = (1) x 1000; $count += @junk });
    $t->feed("\a\a");
    is($calls, 1, 'callback may clear itself');
    is($count, 1000, 'and keeps running afterwards');
}

{
    no warnings 'exiting';
    my $t = Term::Ghostty->new;
    my $fired = 0;
    for my $escape (sub { next }, sub { last }, sub { goto NOWHERE }) {
        $t->on_bell(sub { $fired++; $escape->() });
        my $err;
        LOOP: for (1) { eval { $t->feed("\a") }; $err = $@ }
        like($err, qr/Can't|Label not found/, 'loop control inside a callback becomes an exception');
    }
    is($fired, 3, 'each callback ran');
    $t->on_bell(undef);
    ok(eval { $t->feed("ok"); 1 }, 'terminal not left busy after loop control in a callback');

    my $freed = 0;
    {
        package Guard2;
        sub DESTROY { $freed++ }
    }
    {
        my $g = bless {}, 'Guard2';
        my $u = Term::Ghostty->new(on_bell => sub { $g; next });
        LOOP: for (1) { eval { $u->feed("\a") } }
    }
    is($freed, 1, 'terminal freed after loop control in a callback');
}

{
    package FalseError;
    use overload 'bool' => sub { 0 }, '""' => sub { 'false error' }, fallback => 1;
}
{
    my $calls = 0;
    my $t = Term::Ghostty->new(on_bell => sub { $calls++; die bless {}, 'FalseError' });
    ok(!eval { $t->feed("\a\a"); 1 }, 'exception object that is false in boolean context propagates');
    is(ref $@, 'FalseError', 'as itself');
    is($calls, 1, 'and stops further callbacks');
}

{
    my $stack_n = 5000;
    my $t = Term::Ghostty->new(on_pty_write => sub { my $c = () = (1) x $stack_n });
    $t->feed("\e[");
    my @r = $t->write_until_ground("6nREST");
    is_deeply(\@r, [2, 1], 'write_until_ground result survives a stack-growing callback');
}

done_testing;
