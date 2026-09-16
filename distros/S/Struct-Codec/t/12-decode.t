#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed refaddr reftype);
use Storable qw(freeze thaw);
use B qw(SVf_IOK SVf_NOK SVf_POK SVf_ROK);
use Struct::Codec qw(struct_encode struct_decode);
use re ();   # re::regexp_pattern is not loaded for us on every perl

# THE SAME STRUCTURE BACK.
#
# is_deeply is not enough: a "5" that came back as 5 passes it, and so does a
# utf8 string that lost its flag. So every scalar is also checked by its
# flags through B, and every fixture is round-tripped through Storable as well
# and the two results compared - Storable is the thing this contract claims
# to match, so it is the second opinion.

sub rt { struct_decode(struct_encode($_[0])) }

# What THIS Storable can carry, asked rather than assumed: regexp support
# arrived in Storable 3.06, and an older one DIES with "Can't store REGEXP
# items" rather than saying so, which takes the whole file with it.
my $STORABLE_RE  = eval { thaw(freeze(qr/x/)); 1 } ? 1 : 0;
my $STORABLE_TIE = eval {
    require Tie::Hash;
    tie my %probe, 'Tie::StdHash';
    thaw(freeze(\%probe));
    1;
} ? 1 : 0;

sub kind {
    my $f = B::svref_2object(\$_[0])->FLAGS;
    return q{undef} unless $f & (B::SVf_IOK | B::SVf_NOK | B::SVf_POK | B::SVf_ROK);
    return q{str} if $f & B::SVf_POK;
    return q{int} if $f & B::SVf_IOK;
    return q{num} if $f & B::SVf_NOK;
    return q{other};
}

# ---- scalars keep their kind ---------------------------------------------------
{
    my @cases = (
        [ 5,        'int' ], [ -5, 'int' ], [ 0, 'int' ], [ 16, 'int' ], [ -17, 'int' ],
        [ 1.5,      'num' ], [ -0.25, 'num' ], [ 1e300, 'num' ],
        [ '007',    'str' ], [ '5', 'str' ], [ '', 'str' ], [ "\0", 'str' ],
        [ 'x' x 1000, 'str' ],
        [ undef,    'undef' ],
    );
    for my $c (@cases) {
        my ($in, $k) = @$c;
        my $out = rt($in);
        my $label = defined $in ? (length $in > 20 ? substr($in, 0, 10) . '...' : $in) : 'undef';
        is($out, $in, "$label round-trips");
        is(kind($out), $k, "...as a $k");
    }
    is(rt(~0), ~0, 'UV_MAX round-trips');
    is(rt(-9223372036854775808), -9223372036854775808, 'IV_MIN round-trips')
        if length(sprintf '%d', -1) == 2 && ~0 > 4294967295;
}

# ---- the utf8 flag ----------------------------------------------------------------
{
    my $u = "caf\x{e9}";
    utf8::upgrade($u);   # under 0x100 a literal is bytes until upgraded
    my $b = "caf\xe9";
    my $ou = rt($u); my $ob = rt($b);
    is($ou, $u, 'a character string round-trips');
    ok(utf8::is_utf8($ou), 'and keeps its flag');
    is($ob, $b, 'a byte string round-trips');
    ok(!utf8::is_utf8($ob), 'and does not grow one');
    isnt(struct_encode($u), struct_encode($b), 'so the two encode differently');

    my $wide = "\x{263a}\x{1F600}";
    is(rt($wide), $wide, 'wide characters round-trip');

    # A wide key: perl stores a key that fits in Latin-1 as bytes whatever the
    # string's flag, so "k\x{e9}" upgraded and "k\xe9" are ONE key to it.
    my $h = rt({ "k\x{263a}" => 1, "k\xe9" => 2 });
    is(scalar(keys %$h), 2, q{a wide key and a byte key are two keys});
    ok((grep { utf8::is_utf8($_) } keys %$h) == 1, 'and exactly one has the flag');
    is($h->{"k\x{263a}"}, 1, 'and the wide one is found by its characters');
}

# ---- a number that has been stringified is still a number ------------------------
{
    my $n = 5;    my $s = "$n";
    my $f = 1.5;  my $t = "$f";
    # Older perls set PUBLIC POK when a number is stringified, and the codec
    # dispatches on the public flags by design, so there it writes a string and
    # is right to. Ask this perl what it did rather than assuming a version.
    SKIP: {
        skip 'this perl marks a stringified number as a string', 1
            if kind($n) eq 'str';
        is(kind(rt($n)), 'int', 'an integer that was printed is still an integer');
    }
    SKIP: {
        skip 'this perl marks a stringified number as a string', 1
            if kind($f) eq 'str';
        is(kind(rt($f)), 'num', 'and a float that was printed is still a float');
    }
    my $str = '5'; my $used = $str + 0;
    is(kind(rt($str)), 'str', 'while a string that was used as a number is still a string');
    # Storable itself leaves a private integer flag on an NV it froze, which is
    # what caught this the first time.
    my $nv = 2.5; freeze(\$nv);
    is(rt($nv), 2.5, 'and a float Storable has looked at is still 2.5');
}

# ---- floats are the same bytes everywhere ---------------------------------------
{
    # Hand-built streams, as a little-endian machine writes them, so this
    # asserts the wire form and not merely a round trip on this host.
    my $one_and_half = "S1\x08\x22\x00\x00\x00\x00\x00\x00\xF8\x3F";
    is(struct_decode($one_and_half), 1.5, q{an IEEE little-endian double decodes to its value});
    is(struct_encode(1.5), $one_and_half, q{and encodes back to the same bytes on this machine});
    my $big = 1.0e300;
    is(struct_decode(struct_encode($big)), $big, q{a large magnitude survives});
    is(sprintf(q{%.1f}, struct_decode(struct_encode(-0.0))), q{-0.0}, q{negative zero keeps its sign});
    ok(struct_decode(struct_encode(9**9**9)) == 9**9**9, q{infinity round-trips});
    my $nan = struct_decode(struct_encode(-sin(9**9**9)));
    ok($nan != $nan, q{and so does NaN});
}

# ---- booleans, where perl has them --------------------------------------------------
SKIP: {
    skip 'no native booleans before 5.36', 2 if $] < 5.036;
    # a category an older perl does not know is a COMPILE error, so this
    # pragma is applied only where it exists
    no if $] >= 5.036, warnings => 'experimental::builtin';
    my $t = rt(!!1);
    my $f = rt(!!0);
    ok(builtin::is_bool($t), 'true comes back a boolean');
    ok(builtin::is_bool($f) && !$f, 'and so does false');
}

# ---- containers ---------------------------------------------------------------------
{
    my $d = {
        list  => [1, 'two', 3.5, undef, [ [ [ 'deep' ] ] ]],
        hash  => { a => { b => { c => 'd' } } },
        empty => [],
        none  => {},
        sref  => \'scalar',
        rref  => \\'ref to ref',
    };
    my $o = rt($d);
    is_deeply($o, $d, 'a nested structure round-trips');
    is_deeply($o, thaw(freeze($d)), 'and equals what Storable gives for it');
    is(reftype($o->{sref}), 'SCALAR', 'a scalar ref is a scalar ref');
    is(reftype($o->{rref}), 'REF', 'a ref to a ref is a ref to a ref');
    is($${ $o->{rref} }, 'ref to ref', 'and points where it should');

    my $big = { map { ("key$_" => { id => $_, name => "item $_", tags => [qw(a b c)], score => $_ * 1.5 }) } 1 .. 200 };
    is_deeply(rt($big), $big, '200 nested hashes round-trip');
}

# ---- objects ------------------------------------------------------------------------------
{
    my $o = rt(bless { k => 1 }, 'My::Class');
    is(blessed($o), 'My::Class', 'a blessed hash comes back blessed');
    is($o->{k}, 1, 'with its contents');
    is(blessed(rt(bless [], 'My::List')), 'My::List', 'and a blessed array');
    is(blessed(rt(bless \(my $s = 1), 'My::Scalar')), 'My::Scalar', 'and a blessed scalar');

    my $cls = "Cl\x{e9}ss";
    my $u = rt(bless {}, $cls);
    is(blessed($u), $cls, 'a class with a UTF-8 name survives');

    # DESTROY must not run on a half-built object: bless happens after fill.
    my $destroyed = 0;
    { no strict 'refs'; *{'Dtor::DESTROY'} = sub { $destroyed++ } }
    my $bytes = struct_encode(bless { a => 1 }, 'Dtor');
    $destroyed = 0;
    my $truncated = substr($bytes, 0, length($bytes) - 1);
    eval { struct_decode($truncated) };
    like($@, qr/truncated/, 'a truncated object croaks');
    is($destroyed, 0, 'and DESTROY never saw the half-built object');
    { my $x = struct_decode($bytes); }
    is($destroyed, 1, 'while a whole one is destroyed normally when it goes');
}

# ---- sharing, cycles and aliases -----------------------------------------------------
{
    my $s = [1, 2];
    my $o = rt({ a => $s, b => $s, c => [$s] });
    is(refaddr($o->{a}), refaddr($o->{b}), 'two references to one array share it');
    is(refaddr($o->{c}[0]), refaddr($o->{a}), 'and a third, deeper');
    push @{ $o->{a} }, 3;
    is_deeply($o->{b}, [1, 2, 3], 'a change through one shows through the other');

    my $h = {};
    $h->{me} = $h;
    my $c = rt($h);
    is(refaddr($c->{me}), refaddr($c), 'a cycle comes back as a cycle');
    is_deeply($c, thaw(freeze($h)), 'and matches Storable');

    my $x = 'shared scalar';
    my $al = sub { rt(\@_) }->($x, $x);
    is($al->[0], 'shared scalar', 'an aliased scalar round-trips');
    $al->[0] = 'changed';
    is($al->[1], 'changed', 'and the two slots are still ONE scalar');

    my $obj = bless { n => 1 }, 'Shared::Obj';
    my $so = rt([$obj, $obj]);
    is(refaddr($so->[0]), refaddr($so->[1]), 'a shared object is one object');
    is(blessed($so->[1]), 'Shared::Obj', 'blessed at both ends');

    # A ref to a scalar that is also a slot value.
    my $arr = [];
    $arr->[0] = 5;
    $arr->[1] = \$arr->[0];
    my $ra = rt($arr);
    is(${ $ra->[1] }, 5, 'a ref to a slot scalar points at it');
    $ra->[0] = 6;
    is(${ $ra->[1] }, 6, 'and still does after the slot changes');
}

# ---- what changes, documented --------------------------------------------------------
{
    require Scalar::Util;
    my $inner = [1];
    my $d = { strong => $inner, weak => $inner };
    Scalar::Util::weaken($d->{weak});
    my $o = rt($d);
    ok(!Scalar::Util::isweak($o->{weak}), 'a weak reference comes back strong');
    is(refaddr($o->{weak}), refaddr($o->{strong}), 'but still shared');

    my $dv = Scalar::Util::dualvar(5, 'five');
    is(rt($dv), 'five', 'a dualvar keeps its string');
}

# ---- the kinds that are not data ------------------------------------------------------------
#
# Each comes back as what it was, and where Storable carries the same kind the
# two are compared. Nothing is read through on the way in and nothing runs on
# the way out, except a sub by source, which runs only when asked.
#
# Below 5.12 a regexp has no SV type of its own and the codec refuses the
# kind outright, so the section is skipped there rather than case by case.
SKIP: {
    skip 'a regexp needs perl 5.12 or later', 1 if $] < 5.012;
    my $r = rt(qr/a.b/msix);
    is(ref $r, 'Regexp', 'a regexp comes back a Regexp');
    # against a qr built here, not a literal: how a regexp stringifies
    # changed in 5.14
    is("$r", "" . qr/a.b/msix, 'with its pattern and flags');
    is_deeply([re::regexp_pattern($r)], [re::regexp_pattern(qr/a.b/msix)], 'exactly as re::regexp_pattern sees them');
    ok("A\nB" =~ $r, 'and it matches as it did');
  SKIP: {
        skip 'this Storable cannot carry a regexp', 1 unless $STORABLE_RE;
        is("$r", '' . thaw(freeze(qr/a.b/msix)), 'and agrees with Storable');
    }

    # A flag a perl does not know is a SYNTAX error, not a runtime one, so
    # each is built through a string eval on the perls that have it:
    # /aa is 5.14, /n is 5.22, /xx is 5.26.
    for my $case ([5.026, 'qr/a b/xx', '/xx survives as two x flags'],
                  [5.022, 'qr/(a)/n',  'and /n'],
                  [5.014, 'qr/x/aa',   'and the /aa character set']) {
        my ($since, $src, $name) = @$case;
      SKIP: {
            skip "$src needs perl $since", 1 if $] < $since;
            my $q = eval $src;
            is_deeply([re::regexp_pattern(rt($q))], [re::regexp_pattern($q)], $name);
        }
    }

    my $b = rt(bless qr/x/i, 'My::Re');
    is(blessed($b), 'My::Re', 'a regexp blessed into another class keeps it');
    ok('X' =~ $b, 'and still matches');

    my $wide = "\x{263a}";
    ok($wide =~ rt(qr/$wide/), 'a wide pattern matches a wide string');

    my $q = qr/x/;
    my $o = rt([$q, $q]);
    is(refaddr($o->[0]), refaddr($o->[1]), 'a shared regexp is one regexp');
}

{
    require Tie::Hash;  require Tie::Array;  require Tie::Scalar;
    tie my %th, 'Tie::StdHash';   %th = (a => 1, b => 2);
    tie my @ta, 'Tie::StdArray';  @ta = (1, 2, 3);
    tie my $ts, 'Tie::StdScalar'; $ts = 'seven';

    my $h = rt(\%th);
    is(ref tied(%$h), 'Tie::StdHash', 'a tied hash comes back tied to the same class');
    is_deeply({ %$h }, { a => 1, b => 2 }, 'and its contents are what the object answers');
  SKIP: {
        skip 'this Storable cannot carry a tied hash', 1 unless $STORABLE_TIE;
        is_deeply({ %$h }, { %{ thaw(freeze(\%th)) } }, 'which is what Storable gives too');
    }
    $h->{c} = 3;
    is(tied(%$h)->{c}, 3, 'and a store goes through the tie');

    my $a = rt(\@ta);
    is(ref tied(@$a), 'Tie::StdArray', 'a tied array likewise');
    is_deeply([ @$a ], [1, 2, 3], 'with its contents');

    my $s = rt(\$ts);
    is(ref tied($$s), 'Tie::StdScalar', 'and a tied scalar behind a reference');
    is($$s, 'seven', 'reads through the tie');

    my $slot = sub { rt(\@_) }->($ts);
    is(ref tied($slot->[0]), 'Tie::StdScalar', 'a tied scalar in a slot is tied in that slot');
    is($slot->[0], 'seven', 'and reads through it');

    # A tie object shared with something else in the structure: the object is
    # decoded once and both places hold it.
    my $obj = tied %th;
    my $both = rt([ \%th, $obj ]);
    is(refaddr(tied %{ $both->[0] }), refaddr($both->[1]), 'a tie object shared with a slot is one object');

    # A tie object that refers back to its own tied variable: the variable's
    # reference must be registered BEFORE the object is decoded, or the cycle
    # names a value that is not there yet.
    tie my %self, 'Tie::StdHash';
    tied(%self)->{me} = \%self;
    my $cy = rt(\%self);
    is(refaddr(tied(%$cy)->{me}), refaddr($cy), 'a tie object that refers to its own variable comes back a cycle');
}

{
    sub answer { 42 }
    my $c = rt(\&answer);
    is(refaddr($c), refaddr(\&answer), 'a named sub comes back as THE sub, not a copy');
    is($c->(), 42, 'and runs');
    my $xs = rt(\&Struct::Codec::encode);
    is(refaddr($xs), refaddr(\&Struct::Codec::encode), 'an XSUB by name too');

    my $bytes = struct_encode(sub { 42 });
    my $err = q{};
    { local $Struct::Codec::Eval = 0; eval { struct_decode($bytes); 1 } or $err = $@; }
    like($err, qr/a sub by source needs \$Struct::Codec::Eval/, q{with $Struct::Codec::Eval false a sub by source is refused});
    {
        local $Struct::Codec::Eval = 1;
        is(struct_decode($bytes)->(), 42, 'with $Struct::Codec::Eval true it is built and runs');
        my $b = rt(bless sub { 'x' }, 'Callback');
        is(blessed($b), 'Callback', 'a blessed sub keeps its class');
        is($b->(), 'x', 'and runs');
    }
    {
        my $seen;
        local $Struct::Codec::Eval = sub { $seen = shift; sub { 'mine' } };
        is(struct_decode($bytes)->(), 'mine', 'a code ref in $Struct::Codec::Eval is handed the source');
        like($seen, qr/42/, 'and got the source');
        local $Struct::Codec::Eval = sub { 'not a sub' };
        $err = '';
        eval { struct_decode($bytes); 1 } or $err = $@;
        like($err, qr/did not produce a sub/, 'and must return a sub');
    }
    $err = '';
    eval { struct_decode("S1\x08\x28\x32" . chr(2 * 10) . 'main::nope'); 1 } or $err = $@;
    like($err, qr/sub main::nope is not defined at byte/, 'a name that finds no sub croaks and defines nothing');
    ok(!defined &main::nope, 'and the name is still undefined afterwards');
}

{
    is(refaddr(rt(\*STDOUT)), refaddr(\*STDOUT), 'a named glob comes back as THE glob');
    my $slot = rt([*STDERR]);
    is(ref \$slot->[0], 'GLOB', 'a glob in a slot comes back a glob');
    is("$slot->[0]", '*main::STDERR', 'the same one');

    format STDOUT =
.
    is(refaddr(rt(*STDOUT{FORMAT})), refaddr(*STDOUT{FORMAT}), 'a format comes back as THE format');
    my $err = '';
    eval { struct_decode("S1\x08\x28\x37" . chr(2 * 10) . 'main::nope'); 1 } or $err = $@;
    like($err, qr/format main::nope is not defined/, 'a name that finds no format croaks');

    # A handle by descriptor: a DUP, in this process, that reads the same file.
    open my $in, '<', $0 or die "$0: $!";
    my $d = rt($in);
    is(reftype($d), 'GLOB', 'a lexical filehandle comes back a glob');
    isnt(fileno($d), fileno($in), 'on a descriptor of its own');
    my $line = <$d>;
    like($line, qr/^#!perl/, 'that reads the same file');
    close $d;
    ok(defined fileno($in), 'and closing it leaves the original open');

    my $io = rt(*STDOUT{IO});
    # The class perl gives an IO is not the same on every version: IO::File on
    # a modern perl, FileHandle on 5.10. Both are IO::Handle, which is the
    # property that matters.
    ok($io->isa('IO::Handle'), 'an IO comes back an IO handle (' . blessed($io) . ')');
    is(reftype($io), 'IO', 'and is an IO');
    cmp_ok(fileno($io), '>=', 0, 'on an open descriptor');
}

# ---- agreement with Storable on the whole matrix ------------------------------------------
{
    my @fixtures = (
        5, -5, 1.5, '007', undef, '', "caf\x{e9}",
        [1, 'two', [3]], { a => 1, b => [2, { c => 3 }] },
        bless({ x => 1 }, 'Agree'), \'s', \\'ss',
    );
    for my $i (0 .. $#fixtures) {
        my $f = $fixtures[$i];
        # Storable freezes references only, so a plain scalar goes in behind one.
        my $via_storable = ref $f ? thaw(freeze($f)) : ${ thaw(freeze(\$f)) };
        is_deeply(rt($f), $via_storable, "fixture $i agrees with Storable");
    }
}

done_testing;
