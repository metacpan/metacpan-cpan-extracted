#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use MIME::Base64 qw/encode_base64url/;
use Punk::Push::Subscription;

# These values arrive from a browser and go into a crypto routine and an
# outbound HTTP request. This is a security boundary, not a formality.

my $P256DH = encode_base64url("\x04" . ('k' x 64));   # 65 bytes, uncompressed
my $AUTH   = encode_base64url('a' x 16);              # 16 bytes

sub good { {
    endpoint => 'https://fcm.googleapis.com/fcm/send/abc123',
    keys     => { p256dh => $P256DH, auth => $AUTH },
} }

sub err { my $r = shift; local $@; eval { Punk::Push::Subscription->check($r) }; $@ }

# ---- the shape a browser actually sends -----------------------------------

{
    my $s = Punk::Push::Subscription->new(good());
    isa_ok($s, 'Punk::Push::Subscription');
    is($s->endpoint, 'https://fcm.googleapis.com/fcm/send/abc123', 'endpoint kept');
    is($s->p256dh, $P256DH, 'p256dh kept as base64url');
    is($s->auth,   $AUTH,   'auth kept as base64url');
}

# ---- the endpoint is a URL this server will POST to ------------------------
#
# On a schedule the client chose, with a body the client cannot read. An
# unconstrained one is a server-side request forgery primitive.

for my $bad (
    'http://fcm.googleapis.com/x',      # not https
    '//fcm.googleapis.com/x',           # scheme-relative
    'https:///nohost',                  # no host
    'file:///etc/passwd',
    'gopher://example.com/x',
    'ftp://example.com/x',
    'javascript:alert(1)',
    '/just/a/path',
    'fcm.googleapis.com/x',
) {
    my $r = good();
    $r->{endpoint} = $bad;
    like(err($r), qr/must be an absolute https URL/, "endpoint '$bad' is refused");
}

{
    my $r = good();
    delete $r->{endpoint};
    like(err($r), qr/needs an endpoint/, 'a missing endpoint is refused');
}

# ---- the keys are checked on their DECODED length -------------------------
#
# A base64url decoder that ignores a bad character turns a corrupt key into a
# short one, and the length is what catches that.

{
    my $r = good();
    $r->{keys}{p256dh} = encode_base64url("\x04" . ('k' x 63));  # 64
    like(err($r), qr/p256dh must decode to 65 bytes, got 64/,
        'a 64-byte point is refused, and the message says what it got');
}

{
    my $r = good();
    $r->{keys}{p256dh} = encode_base64url("\x04" . ('k' x 65));  # 66
    like(err($r), qr/p256dh must decode to 65 bytes, got 66/, 'and a 66-byte one');
}

{
    my $r = good();
    $r->{keys}{p256dh} = encode_base64url("\x03" . ('k' x 64));
    like(err($r), qr/uncompressed point, beginning 0x04/,
        'a point that is not uncompressed is refused before import_key_raw');
}

{
    my $r = good();
    $r->{keys}{auth} = encode_base64url('a' x 15);
    like(err($r), qr/auth must decode to 16 bytes, got 15/, 'a short auth is refused');
}

{
    my $r = good();
    $r->{keys}{auth} = encode_base64url('a' x 17);
    like(err($r), qr/auth must decode to 16 bytes, got 17/, 'and a long one');
}

{
    my $r = good();
    $r->{keys}{p256dh} = 'not base64url!!';
    like(err($r), qr/p256dh must be a base64url string/,
        'a key with characters base64url does not use is refused');
}

for my $missing (qw(p256dh auth)) {
    my $r = good();
    delete $r->{keys}{$missing};
    like(err($r), qr/needs a $missing key/, "a missing $missing is refused");
}

{
    my $r = good();
    delete $r->{keys};
    like(err($r), qr/needs keys/, 'missing keys entirely is refused');
}

# ---- the wrapper itself ----------------------------------------------------

like(err(undef),           qr/must be a hashref/, 'undef is not a subscription');
like(err('a string'),      qr/must be a hashref/, 'nor a string');
like(err([good()]),        qr/must be a hashref/, 'nor an arrayref');

done_testing;
