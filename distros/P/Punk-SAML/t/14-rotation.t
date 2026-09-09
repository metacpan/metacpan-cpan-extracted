#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    eval { require Punk; Punk->VERSION('0.45'); require Punk::Test;
           require File::Raw::XML; require Crypt::JWS; 1 }
        or plan skip_all => "Punk, Punk::Test, File::Raw::XML and Crypt::JWS required ($@)";
}

use Punk::SAML ();
use Punk::Plugin::SAML ();
use Crypt::JWS::Key ();
use FakeIdP ();
use MIME::Base64 ();

# Key rotation.
#
# A provider that rotates its signing certificate signs the next assertion
# with something this application has never seen, and every login fails
# with bad_signature until somebody redeploys. The provider did nothing
# wrong: it announced the new key in its metadata, which is the only place
# it ever announces anything. So a failure a rotation would explain buys
# ONE re-read of the metadata and ONE retry.
#
# Nothing here is stubbed and nothing sleeps. The metadata source is a
# `file:` URL and the test REWRITES THE FILE between requests, which is
# what a rotation looks like from this side. The rate limit is then
# asserted the only way that is not a timing assertion: a third key is put
# in the file, and the login that would need it fails - because the second
# refetch never happened. A test that slept to watch an interval expire is
# a test that fails on a loaded smoker.

plan skip_all => 'openssl is required to make certificates'
    unless `openssl version 2>/dev/null`;

# ---- three signers, each with a real certificate ----------------------
#
# A certificate rather than a bare public key, because metadata carries
# X509Certificate and reading it is half of what is under test here.

sub pair {
    my ($cn) = @_;
    my $out = `openssl req -x509 -newkey rsa:2048 -keyout /dev/stdout -nodes -subj "/CN=$cn" -days 3650 2>/dev/null`;
    my ($key)  = ($out // '') =~ /(-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----)/s;
    my ($cert) = ($out // '') =~ /(-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----)/s;
    return ($key, $cert);
}

my (%key, %cert, %idp);
for my $n (qw(a b c)) {
    my ($k, $crt) = pair("rot-$n");
    plan skip_all => "openssl produced no usable key/certificate pair"
        unless $k && $crt;
    $key{$n}  = $k;
    $cert{$n} = $crt;
    $idp{$n}  = FakeIdP->new(key => Crypt::JWS::Key->from_pem($k));
}

# every signer speaks for the same entity: a rotation changes the key, not
# who the provider is
my $ENTITY = 'https://idp.example.com/entity';

sub metadata_with {
    my (@names) = @_;
    my $kd = '';
    for my $n (@names) {
        (my $b = $cert{$n}) =~ s/-----[A-Z ]+-----//g;
        $b =~ s/\s+//g;
        $kd .= qq{<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data>}
             . qq{<ds:X509Certificate>$b</ds:X509Certificate>}
             . qq{</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>};
    }
    return qq{<md:EntityDescriptor }
         . qq{xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" }
         . qq{xmlns:ds="http://www.w3.org/2000/09/xmldsig#" }
         . qq{entityID="$ENTITY">}
         . qq{<md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">}
         . $kd
         . qq{<md:SingleSignOnService }
         . qq{Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" }
         . qq{Location="https://idp.example.com/sso"/>}
         . qq{</md:IDPSSODescriptor></md:EntityDescriptor>};
}

my @files;
sub write_meta {
    my ($file, @names) = @_;
    open my $fh, '>', $file or die "$file: $!";
    print {$fh} metadata_with(@names);
    close $fh;
    return "file:$file";
}
END { unlink @files }

my $seq = 0;
sub meta_file {
    my $f = sprintf 'psaml-rot-%d-%d.xml', $$, ++$seq;
    push @files, $f;
    return $f;
}

# ---- an application per case -----------------------------------------
#
# Separate packages, because the whole point is state that persists across
# requests: the certificates a worker is holding, and when it last re-read
# them. Two cases sharing an application would share both.

sub build {
    my ($pkg, $idp_body, %o) = @_;
    my $extra = $o{metadata_refresh}
        ? ", metadata_refresh => $o{metadata_refresh}" : '';
    $extra = ', metadata_refresh => 0' if defined $o{metadata_refresh}
                                       && !$o{metadata_refresh};
    my $ok = eval qq{
package $pkg;
use Punk;
use Punk::Plugin::SAML;
host 'https://app.example.com';
session secret => 'session-secret-here-32-bytes-ok!';
plugin 'SAML' => { secret => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'$extra };
$idp_body
saml_login '/saml' => { on_login => sub { return } };
1;
};                                                     ## no critic
    my $err = $@;

    # THE BOOT IS FORCED HERE, and the whole file depends on it.
    #
    # on_compile - which is where the metadata is first read - does not run
    # when the package is compiled. It runs at to_app, which Punk::Test
    # calls, and only the first time. So an application built now and not
    # compiled until its first request would read the metadata as it is AT
    # THAT REQUEST, and every rotation below would be picked up by the boot
    # rather than by the refetch this file exists to test. The first draft
    # did exactly that and three cases passed for the wrong reason.
    $ok &&= eval { Punk::Test->new($pkg); 1 };
    $err = $@ if !$ok && !$err;
    return ($ok, $err);
}

# a whole login: start it, then answer it with a Response signed by $who
sub login_with {
    my ($pkg, $who) = @_;
    my $t1 = Punk::Test->new($pkg);
    $t1->get_ok('/saml/login/okta');
    my $loc = $t1->header('Location') // '';
    my ($id)     = $loc =~ /RelayState=(_[0-9a-f]{32})/;
    my ($cookie) = ($t1->header('Set-Cookie') // '') =~ /^_saml_flow=([^;]+)/;

    my $xml = $idp{$who}->sign(
        $idp{$who}->response(in_response_to => $id, issuer => $ENTITY),
        '_assertion1');

    my $t2 = Punk::Test->new($pkg);
    $t2->{jar}{_saml_flow} = $cookie if defined $cookie;
    $t2->post_ok('/saml/acs', form => {
        SAMLResponse => MIME::Base64::encode_base64($xml, ''),
        RelayState   => $id,
    });
    return $t2;
}

# ---- the control: a provider that did NOT rotate ----------------------
#
# The file keeps only key A throughout. A Response signed by B is refused,
# and stays refused after the refetch has read the file and found nothing
# new. Without this, every assertion below would also pass against a
# verifier that accepted any key at all.

{
    my $f = meta_file();
    write_meta($f, 'a');
    my ($ok) = build('SAMLRotControl', qq{saml_idp okta => { metadata => 'file:$f' };});
    ok $ok, 'the control application builds' or diag $@;

    my $r = login_with('SAMLRotControl', 'b');
    is $r->status, 403,
        'a key the provider never published is refused, refetch or no refetch';
}

# ---- the rotation ------------------------------------------------------

{
    my $f = meta_file();
    write_meta($f, 'a');
    my ($ok) = build('SAMLRotate', qq{saml_idp okta => { metadata => 'file:$f' };});
    ok $ok, 'the rotating application builds' or diag $@;

    # it booted holding key A only
    my $app  = SAMLRotate->punk_app;
    my $idps = Punk::Plugin::SAML->_state($app, 'punk_saml.idps');
    is scalar @{ $idps->{okta}{certs} }, 1,
        'it booted with the one certificate the metadata carried';

    # the provider rotates: B is published beside A
    write_meta($f, 'a', 'b');

    my $r = login_with('SAMLRotate', 'b');
    is $r->status, 303,
        'a Response signed with the new key succeeds after one refetch'
        or diag $r->body;

    is scalar @{ $idps->{okta}{certs} }, 2,
        'and the re-read configuration now holds both certificates';
}

# ---- the rate limit ----------------------------------------------------
#
# Straight after the refetch above, on the same application. A third key
# goes into the file, and a Response signed with it must fail: the second
# refetch is inside metadata_refresh and does not happen, so C is never
# read. This is "the stub was called exactly once", asserted through
# behaviour instead of a counter, and without a clock.

{
    my $f = $files[-1];
    write_meta($f, 'a', 'b', 'c');

    my $r = login_with('SAMLRotate', 'c');
    is $r->status, 403,
        'a second rotation within metadata_refresh is not fetched, so it fails';

    my $idps = Punk::Plugin::SAML->_state(SAMLRotate->punk_app, 'punk_saml.idps');
    is scalar @{ $idps->{okta}{certs} }, 2,
        'and the configuration was not re-read: still two certificates';
}

# ---- metadata_refresh => 0 turns the refetch off -----------------------

{
    my $f = meta_file();
    write_meta($f, 'a');
    my ($ok) = build('SAMLRotOff', qq{saml_idp okta => { metadata => 'file:$f' };},
                     metadata_refresh => 0);
    ok $ok, 'an application with metadata_refresh => 0 builds' or diag $@;

    write_meta($f, 'a', 'b');
    my $r = login_with('SAMLRotOff', 'b');
    is $r->status, 403,
        'with metadata_refresh => 0 the metadata is never re-read';
}

# ---- an explicit trio is never overwritten -----------------------------
#
# What the deployer typed is what the deployer meant. A provider given as
# entity_id/sso_url/certs has no metadata source, and this dist does not
# go looking for one.

{
    (my $pem = $cert{a}) =~ s/\s+$//;
    our $TRIO_CERT = $pem;
    my ($ok) = build('SAMLRotTrio', qq{
saml_idp okta => {
    entity_id => '$ENTITY',
    sso_url   => 'https://idp.example.com/sso',
    certs     => \$main::TRIO_CERT,
};});
    ok $ok, 'an application with an explicit trio builds' or diag $@;

    my $r = login_with('SAMLRotTrio', 'b');
    is $r->status, 403,
        'an explicitly configured provider is never refetched';
}

done_testing();
