#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Struct::Codec ();

# THE ONLY FILE ALLOWED TO KNOW THE BYTE LAYOUT.
#
# Every other test asks whether a value comes back; this one asks whether it
# went out as the format says, byte for byte, so a change to the format is a
# deliberate edit here and not a surprise in the decoder. The tags are
# include/sc/sc_format.h's and the expectations are written from that file.

my $HDR = "S1\x08";   # magic, version digit, float encoding (8 = IEEE double LE)
sub enc { Struct::Codec::struct_encode($_[0]) }
sub hex_ { join ' ', map { sprintf '%02x', ord } split //, $_[0] }

# ---- the header ------------------------------------------------------------
is(substr(enc(5), 0, 3), $HDR, q{three-byte header: magic, version digit, float encoding});

# ---- small integers are one byte ---------------------------------------------
is(enc(0),   $HDR . "\x00", '0 is one byte');
is(enc(15),  $HDR . "\x0F", 'and so is 15');
is(enc(-1),  $HDR . "\x1F", '-1 is 0x1F');
is(enc(-16), $HDR . "\x10", '-16 is 0x10, the smallest small negative');

# ---- past the small range, a varint ---------------------------------------------
is(enc(16),  $HDR . "\x20\x10",     '16 needs the UV tag');
is(enc(-17), $HDR . "\x21\x10",     '-17 is NEG of 16, so -(iv+1)');
is(enc(300), $HDR . "\x20\xAC\x02", 'a two-byte varint is little-endian LEB128');
is(enc(~0),  $HDR . "\x20" . ("\xFF" x 9) . "\x01", 'UV_MAX takes ten varint bytes')
    if $Config{uvsize} == 8;

# ---- floats and undef -----------------------------------------------------------
{
    my $b = enc(1.5);
    is(length $b, 3 + 1 + 8, q{an NV is the tag plus eight bytes, whatever the perl's NV is});
    is(substr($b, 3, 1), "\x22", q{under the NV tag});
    is(substr($b, 4), pack(q{d<}, 1.5), q{as an IEEE double in little-endian order});
    is(substr($b, 4), "\x00\x00\x00\x00\x00\x00\xF8\x3F", q{which for 1.5 is these bytes on every machine});
    is(substr(enc(-2.5), 4), "\x00\x00\x00\x00\x00\x00\x04\xC0", q{and -2.5 these});
}
is(enc(undef), $HDR . "\x23", 'undef is one byte');

# ---- strings ----------------------------------------------------------------------
is(enc(''),    $HDR . "\x40",    'the empty string is the short tag with length 0');
is(enc('abc'), $HDR . "\x43abc", 'a short byte string carries its length in the tag');
is(enc('007'), $HDR . "\x43007", 'a string that looks like a number stays a string');
is(enc('x' x 31), $HDR . "\x5F" . ('x' x 31), '31 bytes is still short');
is(enc('x' x 32), $HDR . "\x26\x20" . ('x' x 32), '32 bytes takes the long tag and a varint');
{
    my $u = "caf\x{e9}";
    utf8::upgrade($u);   # a code point under 0x100 is a BYTE string until upgraded
    is(enc($u), $HDR . "\x65caf\xc3\xa9", 'a utf8 string uses the utf8 short tag and its BYTE length');
    my $long = "\x{e9}" x 40;
    utf8::upgrade($long);
    is(substr(enc($long), 3, 2), "\x27\x50", 'a long one the utf8 long tag and its byte length');
}

# ---- containers -------------------------------------------------------------------
is(enc([1, 2]),    $HDR . "\x28\x2B\x02\x01\x02", 'an arrayref is REF, ARRAY, count, values');
is(enc({ a => 1 }), $HDR . "\x28\x2A\x01\x02a\x01", 'a hashref is REF, HASH, count, then key (len<<1) and value');
{
    # A wide character, because perl stores a key that fits in Latin-1 as
    # bytes whatever the string's flag was: "\x{e9}" and "\xe9" are ONE key.
    my $k = "\x{263a}";
    is(enc({ $k => 1 }), $HDR . "\x28\x2A\x01\x07\xe2\x98\xba\x01", 'a utf8 key sets the low bit of its length');
}
is(enc(\5),        $HDR . "\x28\x05",         'a reference to a scalar is REF then the scalar');
is(enc(\\5),       $HDR . "\x28\x28\x05",     'and a reference to that is two REFs');
is(enc(bless({}, 'Foo')), $HDR . "\x29\x06Foo\x2A\x00", 'an object is OBJECT, class as a key, then the referent');

# ---- sharing ------------------------------------------------------------------------
{
    my $s = [1];
    my $b = enc([$s, $s]);
    #            REF ARR 2   REF|TRACK ARR 1 1   REFP off
    is($b, $HDR . "\x28\x2B\x02" . "\xA8\x2B\x01\x01" . "\x2C\x06",
       'a shared referent: the first REF is patched TRACK, the second is REFP to its offset');

    my $t = [1];
    is(enc([$t, [1]]), $HDR . "\x28\x2B\x02\x28\x2B\x01\x01\x28\x2B\x01\x01",
       'two equal but distinct arrays are two REFs and nothing is tracked');
}
{
    # The same SV in two slots. @_ aliases its arguments, so this is the one
    # way to build it without a module.
    my $x = 1;
    my $b = sub { enc(\@_) }->($x, $x);
    is($b, $HDR . "\x28\x2B\x02" . "\x81" . "\x2D\x06",
       'an aliased scalar: the first value tag is patched TRACK, the second is ALIAS');
}
{
    # A cycle: a hash that holds a reference to itself.
    my $h = {};
    $h->{me} = $h;
    my $b = enc($h);
    is($b, $HDR . "\xA8\x2A\x01\x04me\x2C\x03", 'a cycle is a REFP back to the root REF');
}

# ---- the kinds that are not data ------------------------------------------------------
#
# Each is a referent behind REF (or OBJECT, when blessed into something other
# than what the tag implies), and each is written from what perl knows about
# it rather than by reading through it. `key` is the (len<<1|utf8) spelling a
# name or a pattern takes: a varint of that, then the bytes.
sub varint { my ($v) = @_; my $b = ''; while ($v >= 0x80) { $b .= chr(($v & 0x7F) | 0x80); $v >>= 7 } $b . chr($v) }
sub key {
    my ($s) = @_;
    my $u = utf8::is_utf8($s) ? 1 : 0;
    my $bytes = $s; utf8::encode($bytes) if $u;
    return varint(2 * length($bytes) + $u) . $bytes;
}

SKIP: {
    # A regexp became its own SV type in 5.12; before that the codec refuses
    # one by name rather than guessing at its insides.
    skip 'no regexp SVs before 5.12', 4 if $] < 5.012;
    is(enc(qr/x/),        $HDR . "\x28\x2E" . key('x') . key(''),
       'a regexp is REF, REGEXP, the pattern as a key, then the flag letters as a key');
    is(enc(qr/a.b/msix),  $HDR . "\x28\x2E" . key('a.b') . key('msix'),
       'the flag letters in the order re::regexp_pattern gives them');
    is(enc(bless qr/x/i, 'My::Re'), $HDR . "\x29" . key('My::Re') . "\x2E" . key('x') . key('i'),
       'a regexp blessed elsewhere is OBJECT with its class, then REGEXP');
    my $wide = "\x{263a}";
    my $b = enc(qr/$wide/);
    is(substr($b, 5, 1), "\x07", 'a wide pattern is a utf8 key: its byte length with the low bit set');
}

{
    require Tie::Hash;  require Tie::Array;  require Tie::Scalar;
    tie my %th, 'Tie::StdHash';   $th{a} = 1;
    tie my @ta, 'Tie::StdArray';  @ta = (5);
    tie my $ts, 'Tie::StdScalar'; $ts = 7;
    # Tie::StdHash keeps the data in the object, a blessed hash of it; so the
    # object IS {a => 1}, and the tied hash itself is never read.
    is(enc(\%th), $HDR . "\x28\x31" . "\x29" . key('Tie::StdHash') . "\x2A\x01" . key('a') . "\x01",
       'a tied hash is REF, TIED_HASH, then the tie object as a value: nothing is FETCHed');
    is(enc(\@ta), $HDR . "\x28\x30" . "\x29" . key('Tie::StdArray') . "\x2B\x01\x05",
       'a tied array is REF, TIED_ARRAY, then the tie object');
    is(enc(\$ts), $HDR . "\x28\x2F" . "\x29" . key('Tie::StdScalar') . "\x07",
       'a reference to a tied scalar is REF, TIED_SCALAR, then the tie object');
    my $slot = sub { enc(\@_) }->($ts);
    is($slot, $HDR . "\x28\x2B\x01" . "\x2F" . "\x29" . key('Tie::StdScalar') . "\x07",
       'and a tied scalar aliased into a slot is TIED_SCALAR in that slot');
}

{
    sub named { 1 }
    is(enc(\&named), $HDR . "\x28\x32" . key('main::named'),
       'a named sub is REF, CODE_NAME, its fully-qualified name as a key');
    my $anon = sub { 42 };
    require B::Deparse;
    my $src = B::Deparse->new->coderef2text($anon);
    is(enc($anon), $HDR . "\x28\x33" . key($src),
       'an anonymous sub is REF, CODE_SRC, what B::Deparse says as a key');
    is(enc(\&Struct::Codec::encode), $HDR . "\x28\x32" . key('Struct::Codec::encode'),
       'an XSUB with a name is by name like any other');
}

is(enc(\*STDOUT), $HDR . "\x28\x34" . key('main::STDOUT'), 'a glob is REF, GLOB, its name as a key');
is(enc([*STDOUT]), $HDR . "\x28\x2B\x01" . "\x34" . key('main::STDOUT'),
   'a glob copied into a slot is GLOB in that slot, by the same name');
format STDOUT =
.
is(enc(*STDOUT{FORMAT}), $HDR . "\x28\x37" . key('main::STDOUT'),
   'a format is REF, FORMAT, the name of the glob it lives in');
{
    open my $fh, '<', $0 or die "$0: $!";
    is(enc($fh), $HDR . "\x28\x35" . '<' . chr(fileno $fh),
       'a filehandle no name finds is REF, FD_GLOB, its mode byte, its descriptor');
    # The class is whatever perl blesses an IO into: IO::File since 5.12,
    # FileHandle before that. The bytes carry that name, not a fixed one.
    my $io_class = ref *STDOUT{IO};
    is(enc(*STDOUT{IO}), $HDR . "\x29" . key($io_class) . "\x36" . '>' . chr(fileno STDOUT),
       "an IO is OBJECT $io_class, FD_IO, mode, descriptor");
}

# ---- what is still refused, by name ---------------------------------------------------------
{
    my $lexical = 5;
    my $err = '';
    eval { enc(sub { $lexical }); 1 } or $err = $@;
    like($err, qr/^Struct::Codec: cannot encode a closure/,
         'a sub that captured a lexical is refused: its source would not have it');

    require Symbol;
    $err = '';
    eval { enc(Symbol::gensym()); 1 } or $err = $@;
    like($err, qr/^Struct::Codec: cannot encode a GLOB that has no name and no open filehandle/,
         'a glob with no name and nothing open is refused');
}

# ---- a refusal writes nothing that outlives it ---------------------------------------
{
    my $lexical = 1;
    my $err = '';
    eval { enc([ 1, 2, sub { $lexical } ]); 1 } or $err = $@;
    like($err, qr/closure/, 'a refusal deep in a structure croaks');
    is(enc([1, 2]), $HDR . "\x28\x2B\x02\x01\x02", 'and the next encode is unaffected');
}

# ---- depth ---------------------------------------------------------------------------------
{
    my $deep = [];
    my $cur = $deep;
    for (1 .. 5000) { my $n = []; push @$cur, $n; $cur = $n }
    my $err = '';
    eval { enc($deep); 1 } or $err = $@;
    like($err, qr/deeper than 4096/, 'a structure past the depth limit is refused');
}

done_testing;
