use strict;
use warnings;
use Test::More;
use Term::Ghostty;

for (1 .. 100) {
    my $term = Term::Ghostty->new(
        cols => 80,
        rows => 24,
        on_pty_write => sub { my ($t, $b) = @_; },
        on_title_changed => sub { my ($t, $s) = @_; },
    );
    $term->feed("Loop iteration $_\r\n");
    my $txt = $term->get_text;
    $term->feed("\e[?7\$p");
}
pass('Created and destroyed 100 instances without crash');

my $destroyed = 0;
{
    package MyTerm;
    our @ISA = ('Term::Ghostty');
    sub DESTROY {
        my ($self) = @_;
        $destroyed++;
        $self->SUPER::DESTROY;
    }
}

{
    my $term = MyTerm->new(cols => 80, rows => 24);
    $term->on_pty_write(sub { my ($t, $data) = @_; my $c = $t->cols; });
    $term->feed("\e[?7\$p");
}
is($destroyed, 1, 'Subclassed Term::Ghostty was destroyed cleanly when callback uses passed $t');

{
    package Guard;
    sub new { my ($c, $r) = @_; bless { r => $r }, $c }
    sub DESTROY { ${ $_[0]{r} }++ }
}
{
    my $freed = 0;
    {
        my $guard = Guard->new(\$freed);
        my $term = Term::Ghostty->new(on_bell => sub { $guard });
    }
    is($freed, 1, 'callbacks are released with the terminal');

    $freed = 0;
    my $term = Term::Ghostty->new;
    { my $guard = Guard->new(\$freed); $term->on_bell(sub { $guard }) }
    $term->on_bell(undef);
    is($freed, 1, 'replaced callback is released');
}

{
    my %h;
    $h{t} = Term::Ghostty->new(on_bell => sub { delete $h{t}; 1 });
    $h{t}->feed("\a" . ("Z" x 20000) . "\e[?7\$p");
    ok(!exists $h{t}, 'terminal dropped inside its own callback survives');
}

{
    my ($keep, $during);
    my $t = Term::Ghostty->new(on_bell => sub {
        $keep = $_[0];
        $_[0]->DESTROY;
        $during = eval { $_[0]->cols };
    });
    $t->feed("\a" . ("x" x 5000) . "\a");
    is($during, 80, 'object stays usable until the callback returns');
    ok(!eval { $keep->cols; 1 }, 'explicit DESTROY inside a callback takes effect afterwards');
    like($@, qr/destroyed/, 'with a clear message');
}

{
    my $t = Term::Ghostty->new;
    $t->DESTROY;
    ok(!eval { $t->feed('x'); 1 }, 'methods on an explicitly destroyed object croak');
    like($@, qr/object has been destroyed/, 'destroyed message');
    $t->DESTROY;
    pass('second DESTROY is harmless');
}

{
    my $x = 12345;
    my $foreign = bless \$x, 'Foo';
    ok(!eval { Term::Ghostty::cols($foreign); 1 }, 'foreign object rejected');
    like($@, qr/not a Term::Ghostty object/, 'foreign object message');
    Term::Ghostty::DESTROY($foreign);
    is($x, 12345, 'DESTROY ignores a foreign object');
    my $forged = bless \(my $y = 12345), 'Term::Ghostty';
    ok(!eval { $forged->cols; 1 }, 'forged object rejected');
    ok(!eval { Term::Ghostty::cols('Term::Ghostty'); 1 }, 'class name rejected');
}

{
    my $t = Term::Ghostty->new;
    my $moved = bless $t, 'Some::Other';
    undef $t;
    undef $moved;
    pass('re-blessed object is freed without Term::Ghostty::DESTROY');
}

SKIP: {
    skip 'Storable not installed', 2 unless eval { require Storable; 1 };
    my $t = Term::Ghostty->new;
    ok(!eval { Storable::dclone({ t => $t }); 1 }, 'dclone croaks');
    like($@, qr/cannot be serialized or cloned/, 'dclone message');
}

{
    package Freer;
    use overload '""' => sub { undef ${ $_[0]{term} }; 'x' }, '0+' => sub { undef ${ $_[0]{term} }; 10 },
        fallback => 1;
}
for my $call ([feed => 1], [write_until_ground => 1], [set_title => 1], [resize => 1, 10], [resize => 10, 10, 1]) {
    my ($m, @pos) = @$call;
    my $t = Term::Ghostty->new(on_bell => sub { 1 });
    my @args = map { $_ == 1 ? bless({ term => \$t }, 'Freer') : $_ } @pos;
    my $ok = eval { $t->$m(@args); 1 };
    like($ok ? 'survived' : $@, qr/survived|not a Term::Ghostty object/,
         "$m with an argument whose conversion frees the terminal");
}

{
    package FetchTwice;
    sub TIESCALAR { my ($c, $t) = @_; bless { n => 0, t => $t }, $c }
    sub FETCH { my $s = shift; undef ${ $s->{t} } if ++$s->{n} == 2; sub { 1 } }
    package CodeThenName;
    sub TIESCALAR { bless { n => 0 }, shift }
    sub FETCH { ++$_[0]{n} == 1 ? sub { 1 } : 'main::nope' }
}
{
    my $t = Term::Ghostty->new;
    tie my $cb, 'FetchTwice', \$t;
    eval { $t->on_bell($cb) };
    is(tied($cb)->{n}, 1, 'a tied callback is fetched once');
    tie my $cb2, 'CodeThenName';
    my $u = Term::Ghostty->new(on_bell => $cb2);
    is(ref $u->on_bell, 'CODE', 'the stored callback is the value that was checked');
}

{
    my $title = "\x{263A}" . ("T" x 64);
    package RewriteTitle;
    use overload '""' => sub { $title = "\x{263B}" . ("Z" x 100000); 'file:///pwd' }, fallback => 1;
    package main;
    my $t = Term::Ghostty->new(title => $title, pwd => bless({}, 'RewriteTitle'));
    is($t->title, "\x{263A}" . ("T" x 64), 'title is copied before later arguments run code');

    my $key = "scrollback";
    $key .= "";
    package RewriteKey;
    use overload 'bool' => sub { $key = "Z" x 100000; 1 }, fallback => 1;
    package main;
    ok(defined eval { $t->format($key => bless({}, 'RewriteKey')) },
       'format survives an option value that rewrites its key');
}

{
    my $buf = "\e[6n" . ("A" x 3000);
    my $t = Term::Ghostty->new(cols => 100, rows => 40, on_pty_write => sub { $buf = "Z" x 100000 });
    $t->feed($buf);
    my $text = $t->get_text;
    is(($text =~ tr/A//), 3000, 'input is unaffected by a callback reassigning the caller buffer');
}

done_testing;
