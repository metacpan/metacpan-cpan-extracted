#!perl

use strict;
use warnings;

use Test::More;

# --- Razor2::Signature::Ephemeral ---

use_ok('Razor2::Signature::Ephemeral');

{
    my $eph = Razor2::Signature::Ephemeral->new( seed => 42, separator => "10" );
    isa_ok( $eph, 'Razor2::Signature::Ephemeral' );
}

{
    # Deterministic: same seed + content = same digest
    my $eph = Razor2::Signature::Ephemeral->new( seed => 42, separator => "10" );
    my $content = "Line one\nLine two\nLine three\nLine four\n" x 20;
    my $digest1 = $eph->hexdigest($content);
    my $digest2 = $eph->hexdigest($content);

    ok( defined $digest1, "hexdigest returns a value" );
    like( $digest1, qr/^[0-9a-f]{40}$/, "hexdigest returns 40-char hex string" );
    is( $digest1, $digest2, "hexdigest is deterministic with same seed" );
}

{
    # Different seeds produce different digests (for large enough content)
    my $content = "This is a test email body.\n" x 50;
    my $eph1 = Razor2::Signature::Ephemeral->new( seed => 1 );
    my $eph2 = Razor2::Signature::Ephemeral->new( seed => 99 );

    my $d1 = $eph1->hexdigest($content);
    my $d2 = $eph2->hexdigest($content);
    isnt( $d1, $d2, "different seeds produce different digests" );
}

{
    # Short content falls back to hashing entire content
    my $eph = Razor2::Signature::Ephemeral->new( seed => 42 );
    my $short = "tiny";
    my $digest = $eph->hexdigest($short);
    ok( defined $digest, "hexdigest works on short content" );
    like( $digest, qr/^[0-9a-f]{40}$/, "short content still produces valid hex" );
}

# --- encode_separator ---

{
    # "10" means chr(10) which is \n
    my $sep = Razor2::Signature::Ephemeral::encode_separator("10");
    is( $sep, "\n", "encode_separator('10') is newline" );
}

{
    # "13-10" means chr(13).chr(10) which is \r\n
    my $sep = Razor2::Signature::Ephemeral::encode_separator("13-10");
    is( $sep, "\r\n", "encode_separator('13-10') is CRLF" );
}

# --- Razor2::Signature::Whiplash ---

use_ok('Razor2::Signature::Whiplash');

{
    my $wp = Razor2::Signature::Whiplash->new;
    isa_ok( $wp, 'Razor2::Signature::Whiplash' );
    ok( ref $wp->{dpl} eq 'ARRAY' && @{ $wp->{dpl} } > 0,
        "DPL (domain part list) is populated" );
}

{
    # whiplash() returns undef for text with no URLs
    my $wp = Razor2::Signature::Whiplash->new;
    my $result = $wp->whiplash("This is plain text with no URLs at all.");
    ok( !defined $result, "whiplash returns undef for text without URLs" );
}

{
    # whiplash() extracts hosts and produces signatures
    my $wp = Razor2::Signature::Whiplash->new;
    my $text = "Check out http://www.example.com/page for details";
    my ( $sigs, $meta ) = $wp->whiplash($text);

    ok( defined $sigs && ref $sigs eq 'ARRAY', "whiplash returns signature array" );
    ok( @$sigs > 0, "at least one signature produced" );
    ok( defined $meta && ref $meta eq 'HASH', "whiplash returns signature metadata" );

    # Each signature should be 16 hex chars (12 from host + 4 from length)
    for my $sig (@$sigs) {
        like( $sig, qr/^[0-9a-f]{16}$/, "signature '$sig' is 16 hex chars" );
    }
}

{
    # Deterministic: same text produces same signatures
    my $wp = Razor2::Signature::Whiplash->new;
    my $text = "Visit http://spam.example.net/offer now!";
    my ( $sigs1, undef ) = $wp->whiplash($text);
    my ( $sigs2, undef ) = $wp->whiplash($text);
    is_deeply( $sigs1, $sigs2, "whiplash is deterministic" );
}

{
    # whiplash returns undef for empty/undef text
    my $wp = Razor2::Signature::Whiplash->new;
    my $result = $wp->whiplash("");
    ok( !defined $result, "whiplash returns undef for empty string" );

    $result = $wp->whiplash(undef);
    ok( !defined $result, "whiplash returns undef for undef" );
}

# --- canonify ---

{
    my $wp = Razor2::Signature::Whiplash->new;

    is( $wp->canonify("www.something.com"), "something.com",
        "canonify strips www from .com domain" );

    is( $wp->canonify("mail.something.co.uk"), "something.co.uk",
        "canonify handles .co.uk correctly" );

    is( $wp->canonify("host.example.de"), "example.de",
        "canonify handles .de correctly" );
}

# --- extract_hosts ---

{
    my $wp = Razor2::Signature::Whiplash->new;

    my @hosts = $wp->extract_hosts("Click http://www.example.com/path here");
    ok( scalar @hosts > 0, "extract_hosts finds URL in text" );
    ok( ( grep { /example\.com/ } @hosts ), "extract_hosts extracts example.com" );
}

{
    my $wp = Razor2::Signature::Whiplash->new;

    # IP address URL
    my @hosts = $wp->extract_hosts("Visit http://192.168.1.1/page");
    ok( ( grep { $_ eq '192.168.1.1' } @hosts ), "extract_hosts handles IP addresses" );
}

{
    my $wp = Razor2::Signature::Whiplash->new;

    # URL with authority section (user@host)
    my @hosts = $wp->extract_hosts("http://user\@www.example.com/path");
    ok( ( grep { /example\.com/ } @hosts ), "extract_hosts strips authority/user section" );
}

{
    my $wp = Razor2::Signature::Whiplash->new;

    # Hex-encoded URL
    my @hosts = $wp->extract_hosts("http://%77%77%77%2E%65%78%61%6D%70%6C%65%2E%63%6F%6D/page");
    ok( ( grep { /example\.com/ } @hosts ), "extract_hosts decodes hex-encoded URLs" );
}

{
    my $wp = Razor2::Signature::Whiplash->new;

    # No URLs at all
    my @hosts = $wp->extract_hosts("Just plain text, no links here");
    is( scalar @hosts, 0, "extract_hosts returns empty for text without URLs" );
}

{
    my $wp = Razor2::Signature::Whiplash->new;

    # www. autolinks are only detected when the text also contains http:// URLs
    # (the autolink regex captures them, but extract_hosts returns early without
    # http:// — this is existing behavior, not a bug we should fix here)
    my @hosts = $wp->extract_hosts(" www.autolinked.com check http://other.example.com/page");
    ok( ( grep { /autolinked\.com/ } @hosts ), "extract_hosts detects www. autolinks alongside http URLs" );
}

done_testing;
