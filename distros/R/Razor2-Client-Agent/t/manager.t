#!perl

use strict;
use warnings;

use Test::More;

# --- Razor2::Preproc::Manager ---

use_ok('Razor2::Preproc::Manager');

{
    my $mgr = Razor2::Preproc::Manager->new;
    isa_ok( $mgr, 'Razor2::Preproc::Manager' );

    # Default constructor creates all standard preprocessors
    ok( exists $mgr->{deBase64},  "default manager has deBase64" );
    ok( exists $mgr->{deQP},     "default manager has deQP" );
    ok( exists $mgr->{deHTML},   "default manager has deHTML" );
    ok( exists $mgr->{deNewline},"default manager has deNewline" );
    ok( !exists $mgr->{deHTML_comment}, "default manager omits deHTML_comment" );
}

{
    # Selective preprocessor exclusion
    my $mgr = Razor2::Preproc::Manager->new( no_deBase64 => 1, no_deQP => 1 );
    ok( !exists $mgr->{deBase64}, "no_deBase64 disables deBase64" );
    ok( !exists $mgr->{deQP},    "no_deQP disables deQP" );
    ok( exists $mgr->{deHTML},   "deHTML still enabled" );
    ok( exists $mgr->{deNewline},"deNewline still enabled" );
}

{
    # Opt-in deHTML_comment
    my $mgr = Razor2::Preproc::Manager->new( deHTML_comment => 1 );
    ok( exists $mgr->{deHTML_comment}, "deHTML_comment enabled via opt-in" );
}

# --- preproc() pipeline tests ---

{
    # Plain text message: headers stripped, body returned
    my $mgr = Razor2::Preproc::Manager->new;
    my $text = "Subject: Test\nContent-Type: text/plain\n\nHello World\n";
    $mgr->preproc( \$text );

    is( $text, "Hello World", "preproc strips headers and trailing newline" );
}

{
    # Base64 message: decode + strip headers
    my $mgr = Razor2::Preproc::Manager->new;
    my $text = "Content-Type: text/plain\nContent-Transfer-Encoding: base64\n\nSGVsbG8gV29ybGQ=\n";
    $mgr->preproc( \$text );

    like( $text, qr/Hello World/, "preproc decodes base64 body" );
    unlike( $text, qr/Content-Type/, "preproc removes headers from base64 message" );
}

{
    # Quoted-printable message: decode + strip headers
    my $mgr = Razor2::Preproc::Manager->new;
    my $text = "Content-Transfer-Encoding: quoted-printable\n\nHello=20World\n";
    $mgr->preproc( \$text );

    like( $text, qr/Hello World/, "preproc decodes quoted-printable body" );
}

{
    # HTML message: tags stripped + headers stripped
    my $mgr = Razor2::Preproc::Manager->new;
    my $text = "Content-Type: text/html\n\n<HTML><BODY>Hello World</BODY></HTML>\n";
    $mgr->preproc( \$text );

    like( $text, qr/Hello World/, "preproc strips HTML tags from body" );
    unlike( $text, qr/<HTML>/, "preproc removes HTML tags" );
}

{
    # HTML comments stripped when deHTML_comment is enabled
    my $mgr = Razor2::Preproc::Manager->new( deHTML_comment => 1 );
    my $text = "Content-Type: text/html\n\n<HTML><!-- junk -->Real content</HTML>\n";
    $mgr->preproc( \$text );

    unlike( $text, qr/junk/, "preproc removes HTML comments when enabled" );
    like( $text, qr/Real content/, "preproc preserves non-comment content" );
}

{
    # Length tracking with dolength flag
    my $mgr = Razor2::Preproc::Manager->new;
    my $text = "Subject: Test\n\nBody content\n";
    my $lengths = $mgr->preproc( \$text, 1 );

    ok( defined $lengths, "preproc returns length hash when dolength is set" );
    ok( ref $lengths eq 'HASH', "lengths is a hashref" );
    ok( exists $lengths->{'1_orig'}, "lengths has 1_orig" );
    ok( exists $lengths->{'5_after_header_removal'}, "lengths has 5_after_header_removal" );
    ok( $lengths->{'1_orig'} > $lengths->{'5_after_header_removal'},
        "original length > body-only length" );
}

{
    # Without dolength, returns undef
    my $mgr = Razor2::Preproc::Manager->new;
    my $text = "Subject: Test\n\nBody\n";
    my $result = $mgr->preproc( \$text );

    ok( !defined $result, "preproc returns undef without dolength" );
}

{
    # Pipeline with all preprocessors disabled
    my $mgr = Razor2::Preproc::Manager->new(
        no_deBase64  => 1,
        no_deQP      => 1,
        no_deHTML    => 1,
        no_deNewline => 1,
    );
    my $text = "Subject: Test\n\nBody content";
    $mgr->preproc( \$text );

    is( $text, "Body content", "preproc with all preprocessors disabled still strips headers" );
}

# --- Razor2::Engine::VR8 ---

use_ok('Razor2::Engine::VR8');

{
    my $vr8 = Razor2::Engine::VR8->new;
    isa_ok( $vr8, 'Razor2::Engine::VR8' );
    ok( exists $vr8->{whiplash}, "VR8 has whiplash engine" );
    isa_ok( $vr8->{whiplash}, 'Razor2::Signature::Whiplash' );
}

{
    # Signature for text with URLs
    my $vr8 = Razor2::Engine::VR8->new;
    my $text = "Check out http://www.example.com/page for great deals!";
    my $sigs = $vr8->signature( \$text );

    ok( defined $sigs, "VR8 signature returns result for text with URL" );
    ok( ref $sigs eq 'ARRAY', "VR8 signature returns arrayref" );
    ok( @$sigs > 0, "VR8 produces at least one signature" );

    # VR8 returns base64-encoded signatures (hextobase64 output)
    for my $sig (@$sigs) {
        ok( defined $sig && length($sig) > 0, "signature is non-empty" );
    }
}

{
    # Deterministic signatures
    my $vr8 = Razor2::Engine::VR8->new;
    my $text = "Visit http://spam.example.net/offer today!";
    my $sigs1 = $vr8->signature( \$text );
    my $sigs2 = $vr8->signature( \$text );
    is_deeply( $sigs1, $sigs2, "VR8 signatures are deterministic" );
}

{
    # No URLs = no signatures
    my $vr8 = Razor2::Engine::VR8->new;
    my $text = "This is plain text with no URLs at all.";
    my $sigs = $vr8->signature( \$text );

    ok( !defined $sigs, "VR8 returns undef for text without URLs" );
}

# --- Razor2::Client::Engine ---

use_ok('Razor2::Client::Engine');

{
    my @engines = Razor2::Client::Engine::supported_engines();
    ok( scalar @engines >= 2, "supported_engines returns at least 2 engines" );
    ok( ( grep { $_ == 4 } @engines ), "engine 4 is supported" );
    ok( ( grep { $_ == 8 } @engines ), "engine 8 is supported" );
}

{
    # Scalar context returns hashref
    my $engines = Razor2::Client::Engine::supported_engines();
    ok( ref $engines eq 'HASH', "supported_engines returns hashref in scalar context" );
    ok( $engines->{4}, "engine 4 in hashref" );
    ok( $engines->{8}, "engine 8 in hashref" );
}

done_testing;
