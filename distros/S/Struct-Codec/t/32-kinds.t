#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed reftype);
use Struct::Codec qw(struct_encode struct_decode);

# THE KINDS THAT ARE NOT DATA, CROSSED WITH EVERYTHING ELSE.
#
# t/12 proves each kind round-trips on its own. This puts them where real
# structures put them: shared, nested, blessed, inside each other, and in
# quantity - and checks the things a single round trip does not, like a
# regexp still matching what it matched and a tie still answering.

sub rt { struct_decode(struct_encode($_[0])) }

# Test names below quote wide patterns and subjects, so the TAP handles take
# characters rather than warning about every one.
{
    my $tb = Test::More->builder;
    binmode($_, q{:encoding(UTF-8)}) for $tb->output, $tb->failure_output, $tb->todo_output;
}

# ---- regexps: every flag, and they still match ------------------------------------
#
# Below 5.12 a regexp has no SV type of its own and the codec refuses the
# kind outright, so the whole section is skipped there.
SKIP: {
    skip 'a regexp needs perl 5.12 or later', 1 if $] < 5.012;
    my @res = (qr/a.c/, qr/a.c/i, qr/a . c/x, qr/a.c/s, qr/^a/m, qr/a.c/ims,
               qr/(?<n>a)/, qr/\d+/, qr/\x{263a}/, qr/caf\x{e9}/i, qr/[[:alpha:]]+/,
               qr/a|b|c/, qr/(a)(b)?/, qr//, qr/\Q.*\E/);
    push @res, eval 'qr/(a)/n' if $] >= 5.022;
    push @res, eval 'qr/\w/aa', eval 'qr/\w/u', eval 'qr/\w/l' if $] >= 5.014;

    my %probe = ('a.c' => "xAbCx", 'caf' => "CAF\x{c9}", '\d' => 'ab12cd', '\w' => "\x{e9}");
    for my $re (@res) {
        my $o = rt($re);
        is(ref $o, 'Regexp', "$re comes back a Regexp");
        is("$o", "$re", '...stringifying the same');
        for my $subject ("abc", "a\nc", "ABC", "xxaxx", "x\x{263a}y", "caf\x{e9}", "ab12cd", "\x{e9}", "") {
            my @orig = $subject =~ $re;
            my @back = $subject =~ $o;
            is_deeply(\@back, \@orig, "...and matching '" . (length $subject > 6 ? substr($subject, 0, 6) . '..' : $subject) . "' the same way")
                if @orig || @back;
        }
    }

    my $shared = qr/shared/i;
    my $o = rt([$shared, { r => $shared }, [$shared]]);
    is(refaddr($o->[0]), refaddr($o->[1]{r}), 'a regexp shared three ways is one regexp');
    is(refaddr($o->[0]), refaddr($o->[2][0]), '...all three');

    my $sub = bless qr/sub/, 'My::Re';
    my $so = rt($sub);
    is(blessed($so), 'My::Re', 'a regexp blessed into a subclass keeps it');
    ok('a sub b' =~ $so, 'and still matches');

    my $many = rt([ map { qr/n$_/ } 1 .. 200 ]);
    is(scalar @$many, 200, 'two hundred regexps decode');
    ok("n150" =~ $many->[149], '...and the 150th matches n150');
    ok("n150" !~ $many->[148], '...and not the 149th');
}

# ---- ties: still answering, and their object shared ---------------------------------
{
    require Tie::Hash; require Tie::Array; require Tie::Scalar;
    tie my %th, 'Tie::StdHash';  %th = (x => 1, y => 2);
    tie my @ta, 'Tie::StdArray'; @ta = (1, 2, 3);
    tie my $ts, 'Tie::StdScalar'; $ts = 'sv';

    my $o = rt({ h => \%th, a => \@ta, s => \$ts, both => [\%th, \%th] });
    ok(tied %{ $o->{h} }, 'a tied hash comes back tied');
    is(ref tied %{ $o->{h} }, 'Tie::StdHash', '...to the same class');
    is_deeply({ %{ $o->{h} } }, { x => 1, y => 2 }, '...and answers what the object holds');
    ok(tied @{ $o->{a} }, 'a tied array comes back tied');
    is_deeply([ @{ $o->{a} } ], [1, 2, 3], '...and answers');
    ok(tied ${ $o->{s} }, 'a tied scalar comes back tied');
    is(${ $o->{s} }, 'sv', '...and answers');
    is(refaddr(tied %{ $o->{both}[0] }), refaddr(tied %{ $o->{both}[1] }),
       'one tied hash referenced twice comes back as two ties to ONE object');
    $o->{both}[0]{z} = 3;
    is($o->{both}[1]{z}, 3, '...so a write through one shows through the other');

    # a tie whose object is a plain hash of state, nested inside data
    {
        package Counter;
        sub TIESCALAR { my ($c, $n) = @_; bless { n => $n }, $c }
        sub FETCH { $_[0]{n}++ }
        sub STORE { $_[0]{n} = $_[1] }
    }
    tie my $ctr, 'Counter', 10;
    my $c = rt([ \$ctr, \$ctr ]);
    is(${ $c->[0] }, 10, 'a stateful tie comes back with its state');
    is(${ $c->[1] }, 11, '...shared: the second read through the other slot continues the count');
}

# ---- subs by name: identity, and shared ------------------------------------------------
{
    sub named_one { 'one' }
    sub named_two { 'two' }
    my $o = rt({ a => \&named_one, b => \&named_one, c => \&named_two, list => [ \&named_one ] });
    is(refaddr($o->{a}), refaddr(\&named_one), 'a named sub comes back as THAT sub');
    is(refaddr($o->{b}), refaddr($o->{a}), '...and shared references to it are one');
    is($o->{c}->(), 'two', 'a second sub is itself');
    is($o->{list}[0]->(), 'one', 'and inside a list');

    my $err = '';
    my $bytes = struct_encode(\&named_one);
    { no strict 'refs'; no warnings 'redefine'; local *{'main::named_one'}; delete $main::{named_one} }
    eval { struct_decode($bytes); 1 } or $err = $@;
    like($err, qr/named_one/, 'a sub by name that no longer exists is an error naming it');
    { no strict 'refs'; *{'main::named_one'} = sub { 'one' } }
}

# ---- subs by source, under $Struct::Codec::Eval -------------------------------------------
{
    my $bytes = struct_encode({ f => sub { 6 * 7 }, g => [ sub { join '-', @_ } ] });
    my $err = q{};
    { local $Struct::Codec::Eval = 0; eval { struct_decode($bytes); 1 } or $err = $@; }
    like($err, qr/Eval/, q{with $Struct::Codec::Eval false a sub by source is refused});

    {
        local $Struct::Codec::Eval = 1;
        my $o = struct_decode($bytes);
        is($o->{f}->(), 42, 'with it, the sub runs');
        is($o->{g}[0]->(1, 2), '1-2', '...with arguments');
    }
    {
        my @seen;
        local $Struct::Codec::Eval = sub { push @seen, $_[0]; return sub { 'from the evaluator' } };
        my $o = struct_decode($bytes);
        is($o->{f}->(), 'from the evaluator', 'a coderef Eval decides what a source becomes');
        is(scalar @seen, 2, q{...and saw both sources});
        # in whichever order the hash walked them: key order is per hash
        is(scalar(grep { /6 \* 7|42/ } @seen), 1, q{...one of which read as the first sub});
        is(scalar(grep { /join/ } @seen), 1, q{...and the other as the second});
    }

    my $lex = 3;
    $err = '';
    eval { struct_encode(sub { $lex }); 1 } or $err = $@;
    like($err, qr/closure/, 'a closure over a lexical is refused on encode');
    ok(eval { struct_encode(sub { my $y = 1; $y }); 1 }, 'while a sub with only its own lexicals is fine');
}

# ---- globs and handles ------------------------------------------------------------------------
{
    my $o = rt({ out => \*STDOUT, err => \*STDERR, both => [\*STDOUT, \*STDOUT] });
    is(refaddr($o->{out}), refaddr(\*STDOUT), '\\*STDOUT comes back as the real STDOUT glob');
    is(refaddr($o->{err}), refaddr(\*STDERR), 'and STDERR');
    is(refaddr($o->{both}[0]), refaddr($o->{both}[1]), 'shared references to it are one');
    ok(defined fileno($o->{out}), 'and it is open');

    open my $fh, '<', $0 or die "$0: $!";
    my $first = <$fh>;
    seek $fh, 0, 0;
    my $h = eval { rt($fh) };
    SKIP: {
        skip "handles by descriptor not carried: $@", 3 unless $h;
        ok(ref $h, 'a lexical handle comes back');
        isnt(fileno($h), fileno($fh), '...as its own descriptor');
        is(scalar <$h>, $first, '...on the same file');
        close $h;
        ok(defined fileno($fh), 'and closing the copy leaves the original open');
    }
}

# ---- all of them at once, twice, identically -------------------------------------------------
{
    tie my %th, 'Tie::StdHash'; $th{k} = 'v';
    my $everything = {
        tie => \%th,
        sub => \&named_two,
        glob => \*STDIN,
        data => [1, 'two', { three => 3 }],
        obj => bless({ n => 1 }, 'Holder'),
    };
    # the regexp kinds only where this perl has them
    if ($] >= 5.012) { $everything->{re} = qr/x/i; $everything->{obj}{re} = qr/y/ }
    my $b1 = struct_encode($everything);
    my $b2 = struct_encode(struct_decode($b1));
    # not byte-identical: hash iteration order is perturbed per hash by perl
    is(length $b2, length $b1, q{a structure of every kind re-encodes to the same size});
    my $o = struct_decode($b2);
    is(ref $o->{re}, 'Regexp', 'and the regexp is there') if $] >= 5.012;
    ok(tied %{ $o->{tie} }, 'the tie');
    is($o->{sub}->(), 'two', 'the sub');
    is(refaddr($o->{glob}), refaddr(\*STDIN), 'the glob');
    is(blessed($o->{obj}), 'Holder', 'the object');
    ok('yy' =~ $o->{obj}{re}, 'and a regexp inside it') if $] >= 5.012;
}

done_testing;
