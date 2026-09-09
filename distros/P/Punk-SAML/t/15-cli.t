#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    eval { require File::Raw::XML; require Crypt::JWS; 1 }
        or plan skip_all => "File::Raw::XML and Crypt::JWS are required ($@)";
}

use Punk::SAML ();
use Punk::Command::SAML ();
use FakeIdP ();
use MIME::Base64 ();

# The four subcommands.
#
# They are the only part of this distribution a person runs directly, and
# they are what somebody reaches for when a login is failing and nobody
# knows why. A `verify` that printed "accepted" for a Response the plugin
# would refuse would send that person looking in the wrong place, so what
# is asserted here is that the CLI and the plugin agree.
#
# Output is captured rather than printed: a test that scrolls its subject
# past the reader is not checking it.

sub capture {
    my ($code) = @_;
    my $out = '';
    my $rc;
    {
        open my $old, '>&', \*STDOUT or die "dup: $!";
        close STDOUT;
        open STDOUT, '>', \$out or die "reopen: $!";
        $rc = eval { $code->() };
        my $err = $@;
        close STDOUT;
        open STDOUT, '>&', $old or die "restore: $!";
        close $old;
        die $err if $err;
    }
    return ($rc, $out);
}

my @files;
END { unlink @files }
sub tmpfile {
    my ($content) = @_;
    my $f = sprintf 'psaml-cli-%d-%d.tmp', $$, scalar @files;
    push @files, $f;
    open my $fh, '>:raw', $f or die "$f: $!";
    print {$fh} $content;
    close $fh;
    return $f;
}

# ---- usage -------------------------------------------------------------

{
    my ($rc, $out) = capture(sub { Punk::Command::SAML->run() });
    like $out, qr/punk saml key/, 'no subcommand prints the usage';
    like $out, qr/punk saml verify/, '  ... listing all four';

    (my $rc2, $out) = capture(sub { Punk::Command::SAML->run('nope') });
    like $out, qr/punk saml key/, 'an unknown subcommand prints it too';
}

# an unknown subcommand must not reach `can` and call something that is
# not a subcommand: `run` builds a method name from user input
{
    my ($rc, $out) = capture(sub { Punk::Command::SAML->run('usage') });
    like $out, qr/punk saml key/,
        'a name that happens to be a method of this class is still usage-safe';
}

# ---- punk saml key -----------------------------------------------------

{
    my ($rc, $out) = capture(sub { Punk::Command::SAML->run('key') });
    is $rc, 0, 'key exits zero';
    chomp(my $k = $out);
    like $k, qr{^[A-Za-z0-9_-]+$}, 'the secret is base64url with no padding';
    is length($k), 43, '  ... of 32 bytes, which is the width the cookie MAC wants';

    my (undef, $out2) = capture(sub { Punk::Command::SAML->run('key') });
    isnt $out2, $out, 'and a second one differs, which is the only property that matters';
}

# ---- punk saml metadata ------------------------------------------------

{
    my ($rc, $out) = capture(sub {
        Punk::Command::SAML->run('metadata',
            entity_id => 'https://app.example.com/saml/metadata',
            acs_url   => 'https://app.example.com/saml/acs')
    });
    is $rc, 0, 'metadata exits zero';
    like $out, qr/<md:EntityDescriptor/, 'and prints an EntityDescriptor';
    like $out, qr{entityID="https://app\.example\.com/saml/metadata"},
        'with the entity id it was given';
    like $out, qr{Location="https://app\.example\.com/saml/acs"},
        'and the ACS location';
}

# ---- punk saml idp -----------------------------------------------------

my $idp = FakeIdP->new;

# a provider's metadata, on disk, which is the form the subcommand exists
# to make readable
my $META = <<'XML';
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
 xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
 entityID="https://idp.example.com/entity">
<md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol"
 WantAuthnRequestsSigned="true">
<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data>
<ds:X509Certificate>CERTIFICATE-GOES-HERE</ds:X509Certificate>
</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>
<md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
<md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
 Location="https://idp.example.com/sso"/>
</md:IDPSSODescriptor></md:EntityDescriptor>
XML

SKIP: {
    my $out = `openssl req -x509 -newkey rsa:2048 -keyout /dev/null -nodes -subj "/CN=cli" -days 3650 2>/dev/null`;
    my ($b) = ($out // '') =~ /-----BEGIN CERTIFICATE-----(.*?)-----END/s;
    skip 'openssl is required for a certificate the reader will accept', 7
        unless $b;
    $b =~ s/\s+//g;
    (my $meta = $META) =~ s/<ds:X509Certificate>.*?</<ds:X509Certificate>$b</s;

    my $f = tmpfile($meta);

    my ($rc, $got) = capture(sub { Punk::Command::SAML->run('idp', $f) });
    is $rc, 0, 'idp exits zero on a readable document';
    like $got, qr{^entity_id\s+https://idp\.example\.com/entity$}m,
        'and prints the entity id';
    like $got, qr{^sso_url\s+https://idp\.example\.com/sso$}m,
        'the SSO URL';
    like $got, qr/^signed\s+WantAuthnRequestsSigned=true$/m,
        'whether the provider demands signed requests';
    like $got, qr/^cert 0\s+sha256:[0-9a-f]{64}$/m,
        'and a fingerprint per certificate, which is what gets read down a phone';
    like $got, qr{^nameid\s+urn:oasis:names:tc:SAML:1\.1:nameid-format:emailAddress$}m,
        'and the NameID formats';

    # `file:` is accepted, because that is the form the plugin option takes
    # and somebody will paste it
    my (undef, $got2) = capture(sub { Punk::Command::SAML->run('idp', "file:$f") });
    is $got2, $got, 'a file: prefix reads the same file';
}

# a document that is not metadata is refused, and says so rather than
# dying with a stack trace at somebody debugging a login
{
    my $f = tmpfile('<nonsense/>');
    my ($rc, $out) = capture(sub { Punk::Command::SAML->run('idp', $f) });
    is $rc, 1, 'idp exits non-zero on a document it cannot read';
    like $out, qr/^refused: /, '  ... printing a refusal, not a stack trace';
}

{
    my ($rc, $out) = capture(sub { Punk::Command::SAML->run('idp') });
    like $out, qr/punk saml idp/, 'idp with no argument prints the usage';
}

# ---- punk saml verify --------------------------------------------------
#
# The one that matters. `--at` is what makes it usable at all: a Response
# saved from a browser is expired within minutes, and every one somebody
# brings to be looked at is old.

my $WHEN = 1757000000;                       # a fixed instant, so nothing here drifts
my $RESPONSE = $idp->sign($idp->response(now => $WHEN, in_response_to => '_flow1'),
                          '_assertion1');

my @verify_args = (
    entity_id      => $idp->sp_entity,
    idp_entity_id  => $idp->entity_id,
    acs_url        => $idp->acs,
    certs          => $idp->certs,
    in_response_to => '_flow1',
    idp            => 'okta',
);

{
    my $f = tmpfile($RESPONSE);
    my ($rc, $out) = capture(sub {
        Punk::Command::SAML->run('verify', $f, '--at' => $WHEN, @verify_args)
    });
    is $rc, 0, 'verify accepts a good Response when --at is inside its window'
        or diag $out;
    like $out, qr/^accepted$/m, '  ... and says so';
    like $out, qr/^\s+name_id\s+jo\@example\.com$/m, '  ... with the name id';
    like $out, qr/^\s+groups\s+staff, eng$/m,
        '  ... and the attributes, multi-valued ones joined';
}

# the same document, without --at, is expired: the assertion is from a
# fixed instant in the past and this is the whole reason --at exists
{
    my $f = tmpfile($RESPONSE);
    my ($rc, $out) = capture(sub {
        Punk::Command::SAML->run('verify', $f, @verify_args)
    });
    is $rc, 1, 'and refuses the same Response at the real time';
    like $out, qr/^refused: expired$/m,
        '  ... naming the check, because here the reason IS for the reader';
}

# base64 as it came out of the form, rather than XML
{
    my $f = tmpfile(MIME::Base64::encode_base64($RESPONSE));
    my ($rc, $out) = capture(sub {
        Punk::Command::SAML->run('verify', $f, '--at' => $WHEN, @verify_args)
    });
    is $rc, 0, 'a base64 SAMLResponse field is decoded and verified'
        or diag $out;
    like $out, qr/^accepted$/m, '  ... to the same answer as the raw XML';
}

# the CLI and the plugin have to agree, or the CLI is worse than nothing
{
    (my $tampered = $RESPONSE) =~ s/jo\@example\.com/admin\@example.com/;
    my $f = tmpfile($tampered);
    my ($rc, $out) = capture(sub {
        Punk::Command::SAML->run('verify', $f, '--at' => $WHEN, @verify_args)
    });
    is $rc, 1, 'a tampered Response is refused';
    like $out, qr/^refused: bad_digest$/m,
        '  ... with the same code the plugin refuses it with';
}

{
    my ($rc, $out) = capture(sub { Punk::Command::SAML->run('verify') });
    like $out, qr/punk saml verify/, 'verify with no file prints the usage';
}

done_testing();
