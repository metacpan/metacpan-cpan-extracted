#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use File::Spec ();
use Punk::Test;
use Punk::Plugin::I18n ();

# Punk::Plugin::I18n - what survives the catalogue, byte for byte.
#
# The suite had no non-ASCII coverage at all before this file, and there
# were three separate encoding faults behind that silence:
#
#   1. the arena kept no flag, so a producer that handed over Latin-1 had
#      it relabelled UTF-8 on the way out. Fixed by the block, which
#      records the flag per string.
#   2. pi_interpolate appended a substitution's raw bytes into a buffer
#      that was then flagged UTF-8. Fixed with sv_catsv. Frozen had
#      nothing to do with this one; it was ordinary broken code sitting
#      beside the interesting problem, and it was reachable from a form
#      field.
#   3. _interpolate never set the flag at all, so a test through the seam
#      asked a different question from the request path - which is why
#      neither of the first two was ever caught.
#
# Only the DEFAULT path was ever correct, and only by accident:
# File::Raw::JSON calls sv_utf8_decode on every decoded string, so the flag
# happened to match the bytes.
#
# Assertions are on the PV, not on an already-decoded string. A test that
# compares characters cannot tell "cafe-acute" from "cafe-acute encoded
# twice", which is the failure being guarded against.

sub pv {
    my ($s) = @_;
    return '(undef)' unless defined $s;
    my $c = $s;
    utf8::encode($c) if utf8::is_utf8($c);
    return unpack 'H*', $c;
}

my $ACUTE = "caf\xc3\xa9";              # cafe-acute, as UTF-8 octets
my $CJK   = "\xe6\x97\xa5\xe6\x9c\xac"; # two CJK ideographs, as UTF-8 octets

sub write_cat {
    my ($dir, $tag, $json) = @_;
    open my $fh, '>:raw', File::Spec->catfile($dir, "$tag.json") or die $!;
    print $fh $json;
    close $fh;
}

my $n = 0;
sub app_for {
    my ($dir, %extra) = @_;
    my $pkg = 'Utf8App' . ++$n;
    my $code = qq{
        package $pkg;
        use Punk;
        plugin 'I18n' => { dir => '$dir', default => 'en' };
        get '/v'    => sub { \$_[0]->text(\$_[0]->locale('cafe')) };
        get '/cjk'  => sub { \$_[0]->text(\$_[0]->locale('cjk')) };
        get '/k'    => sub { \$_[0]->text(\$_[0]->locale("$CJK")) };
        get '/sub'  => sub {
            \$_[0]->text(\$_[0]->locale('greeting', name => "Ren\\xe9"));
        };
        1;
    };
    eval $code or die $@;
    return $pkg;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
write_cat($dir, 'en', qq({"cafe":"$ACUTE","cjk":"$CJK","$CJK":"key was found",)
                     . qq("greeting":"$ACUTE de {name}"}));

# ---- the producer that works, which must not regress -------------------------
{
    my $t = Punk::Test->new(app_for($dir));

    $t->get_ok('/v');
    is(pv($t->body), unpack('H*', $ACUTE),
        'a Latin-1-representable character survives as UTF-8 octets');
    ok(utf8::valid($t->body), 'and the result is valid UTF-8');

    $t->get_ok('/cjk');
    is(pv($t->body), unpack('H*', $CJK),
        'a character outside Latin-1 survives too');

    $t->get_ok('/k');
    is($t->body, 'key was found', 'a non-ASCII KEY matches - pi_hash is over bytes');
}

# ---- a producer that hands back downgraded strings ---------------------------
#
# A decoder configured utf8 => 0, a database column, a hand-built hash.
# The old arena kept no flag, so _locale relabelled Latin-1 bytes as UTF-8
# and the response was malformed - flagged, and not valid. The block records
# the flag per string, so what went in is what comes out.
#
# The stand-in overrides File::Raw::slurp, which is what register calls
# through the json plugin. It used to override file_json_decode, and when
# the read moved to the plugin tail that override silently stopped covering
# anything - the tests kept passing while measuring nothing.
{
    my $d2 = File::Temp::tempdir(CLEANUP => 1);
    write_cat($d2, 'en', '{"unused":"x"}');

    my $body;
    {
        no warnings 'redefine';
        local *File::Raw::slurp = sub {
            return { cafe => "caf\xe9", greeting => 'Bonjour, {name}' };
        };
        my $t = Punk::Test->new(app_for($d2));
        $t->get_ok('/v');
        $body = $t->body;
    }

    # Punk cannot know a downgraded string was meant as Latin-1, so it does
    # not guess: the bytes are returned as given. What it must never do is
    # claim they are UTF-8.
    is(pv($body), unpack('H*', "caf\xe9"),
        'a downgraded producer gets its own bytes back, unchanged');
    ok(!(utf8::is_utf8($body) && !utf8::valid($body)),
        'and they are never flagged UTF-8 while not being valid UTF-8');
}

# ---- interpolation, which Frozen did NOT fix ---------------------------------
#
# pi_interpolate used to sv_catpvn the substitution's raw bytes into a buffer
# that _locale then flagged UTF-8. So a NON-ASCII catalogue entry - flagged,
# correctly encoded - plus a downgraded substitution put a raw Latin-1 byte
# inside a string claiming to be UTF-8. Corruption, reachable from user input
# today through $c->locale($key, name => $form_value).
#
# The catalogue entry has to be non-ASCII for this to bite. Two unflagged
# byte strings concatenating is merely consistent; the fault is mixing an
# encoded string with an unencoded one and labelling the result.
#
# Frozen does not fix this - the block hands back exactly what it was given.
# The fix is sv_catsv, which is the primitive that knows both sides' flags.
{
    my $t = Punk::Test->new(app_for($dir));
    $t->get_ok('/sub');
    my $body = $t->body;

    ok(!(utf8::is_utf8($body) && !utf8::valid($body)),
        'a downgraded substitution does not corrupt a non-ASCII entry');
    is(pv($body), unpack('H*', "$ACUTE de Ren\xc3\xa9"),
        'and the substitution is upgraded rather than pasted in raw');
}

# ---- the seam and the request path answer the same question -------------------
#
# _interpolate never set the flag at all, so a test through it could not see
# either bug above: it was asking a different question from the request path.
# It now takes the flag from its own argument, which is what the block
# records for a catalogue string.
#
# The seam is therefore handed a CHARACTER string, because that is what the
# request path has once the block's flag is applied. Handing it the octets
# would compare a byte string against a character string and call the
# difference a bug.
{
    my $entry = "$ACUTE de {name}";
    utf8::decode($entry);
    my $seam = Punk::Plugin::I18n->_interpolate($entry, name => "Ren\xe9");

    my $t = Punk::Test->new(app_for($dir));
    $t->get_ok('/sub');

    is(pv($seam), pv($t->body),
        '_interpolate and $c->locale produce the same bytes');
    is(utf8::is_utf8($seam) ? 1 : 0, utf8::is_utf8($t->body) ? 1 : 0,
        'and the same flag');
    ok(utf8::valid($seam), 'and the seam result is valid UTF-8');
}

done_testing;
