#!perl

use strict;
use warnings;

use Test::More;

# --- Razor2::Preproc::deBase64 ---

use_ok('Razor2::Preproc::deBase64');

{
    my $dec = Razor2::Preproc::deBase64->new;
    isa_ok( $dec, 'Razor2::Preproc::deBase64' );
}

{
    my $dec = Razor2::Preproc::deBase64->new;

    # isit() detects base64 content-transfer-encoding
    my $b64_msg = "Content-Type: text/plain\nContent-Transfer-Encoding: base64\n\nSGVsbG8gV29ybGQ=\n";
    ok( $dec->isit( \$b64_msg ), "isit() detects base64 encoding" );

    my $plain_msg = "Content-Type: text/plain\n\nHello World\n";
    ok( !$dec->isit( \$plain_msg ), "isit() rejects non-base64 content" );
}

{
    my $dec = Razor2::Preproc::deBase64->new;

    # doit() decodes base64 body
    my $text = "Content-Type: text/plain\nContent-Transfer-Encoding: base64\n\nSGVsbG8gV29ybGQ=\n";
    $dec->doit( \$text );

    like( $text, qr/Hello World/, "doit() decodes base64 to plaintext" );
    like( $text, qr/^Content-Type: text\/plain/, "doit() preserves headers" );
}

# --- Razor2::Preproc::deQP ---

use_ok('Razor2::Preproc::deQP');

{
    my $dec = Razor2::Preproc::deQP->new;
    isa_ok( $dec, 'Razor2::Preproc::deQP' );
}

{
    my $dec = Razor2::Preproc::deQP->new;

    my $qp_msg = "Content-Transfer-Encoding: quoted-printable\n\nHello=20World=0D=0A";
    ok( $dec->isit( \$qp_msg ), "isit() detects quoted-printable encoding" );

    my $plain_msg = "Content-Type: text/plain\n\nHello\n";
    ok( !$dec->isit( \$plain_msg ), "isit() rejects non-QP content" );
}

{
    my $dec = Razor2::Preproc::deQP->new;

    my $text = "Content-Transfer-Encoding: quoted-printable\n\nHello=20World";
    $dec->doit( \$text );

    like( $text, qr/Hello World/, "doit() decodes =20 to space" );
}

{
    my $dec = Razor2::Preproc::deQP->new;

    # Soft line break removal
    my $text = "Content-Transfer-Encoding: quoted-printable\n\nThis is a long=\nline that continues";
    $dec->doit( \$text );

    like( $text, qr/This is a longline that continues/,
        "doit() removes soft line breaks" );
}

# --- Razor2::Preproc::deNewline ---

use_ok('Razor2::Preproc::deNewline');

{
    my $dec = Razor2::Preproc::deNewline->new;
    isa_ok( $dec, 'Razor2::Preproc::deNewline' );
}

{
    my $dec = Razor2::Preproc::deNewline->new;

    # isit() always returns true
    ok( $dec->isit(), "isit() always returns true" );
}

{
    my $dec = Razor2::Preproc::deNewline->new;

    # doit() strips trailing newlines from body
    my $text = "Subject: Test\n\nBody text\n\n\n";
    $dec->doit( \$text );

    like( $text, qr/Body text$/, "doit() strips trailing newlines from body" );
    like( $text, qr/^Subject: Test/, "doit() preserves headers" );
}

{
    my $dec = Razor2::Preproc::deNewline->new;

    # No trailing newlines = no change
    my $text = "Subject: Test\n\nBody text";
    my $orig = $text;
    $dec->doit( \$text );

    is( $text, $orig, "doit() leaves text unchanged when no trailing newlines" );
}

# --- Razor2::Preproc::deHTML_comment ---

use_ok('Razor2::Preproc::deHTML_comment');

{
    my $dec = Razor2::Preproc::deHTML_comment->new;
    isa_ok( $dec, 'Razor2::Preproc::deHTML_comment' );
}

{
    my $dec = Razor2::Preproc::deHTML_comment->new;

    # isit() detects HTML content
    my $html_msg = "Content-Type: text/html\n\n<HTML><BODY>Hello</BODY></HTML>";
    ok( $dec->isit( \$html_msg ), "isit() detects HTML in body" );

    my $html_hdr = "Content-Type: text/html\n\nPlain but typed as html";
    ok( $dec->isit( \$html_hdr ), "isit() detects text/html content-type" );

    my $plain = "Content-Type: text/plain\n\nJust text";
    ok( !$dec->isit( \$plain ), "isit() rejects plain text" );
}

{
    my $dec = Razor2::Preproc::deHTML_comment->new;

    # doit() strips HTML comments
    my $text = "Subject: Test\n\n<HTML><!-- spam obfuscation -->Real content<!-- more junk --></HTML>";
    $dec->doit( \$text );

    unlike( $text, qr/spam obfuscation/, "doit() removes HTML comments" );
    unlike( $text, qr/more junk/, "doit() removes all HTML comments" );
    like( $text, qr/Real content/, "doit() preserves non-comment content" );
}

{
    my $dec = Razor2::Preproc::deHTML_comment->new;

    # Multi-line comments
    my $text = "Subject: Test\n\n<HTML><!--\nmulti\nline\n-->Content</HTML>";
    $dec->doit( \$text );

    unlike( $text, qr/multi/, "doit() removes multi-line HTML comments" );
    like( $text, qr/Content/, "doit() preserves content after multi-line comment" );
}

done_testing;
