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
use Punk::SAML::Response ();
use MIME::Base64 ();
use FakeIdP ();

my $idp = FakeIdP->new;
my %base = (
    idp            => 'okta',
    entity_id      => $idp->sp_entity,
    idp_entity_id  => $idp->entity_id,
    acs_url        => $idp->acs,
    certs          => $idp->certs,
    in_response_to => '_flow1',
);

sub verify_ok {
    my ($xml, %o) = @_;
    return scalar eval { Punk::SAML::Response->verify($xml, %base, %o) };
}
sub verify_err {
    my ($xml, %o) = @_;
    local $@;
    eval { Punk::SAML::Response->verify($xml, %base, %o) };
    return $@;
}

# ---- the positive control --------------------------------------------
#
# Every negative below is only meaningful because this passes. A suite of
# refusals with no control is a suite that would pass if verify() threw
# on everything.

my $signed = $idp->sign($idp->response, '_assertion1');
{
    my $id = verify_ok($signed);
    ok $id, 'a well-formed signed Response verifies' or diag $@;
    is $id->{name_id}, 'jo@example.com', 'the name id';
    is $id->{idp}, 'okta', 'the provider name';
    is $id->{assertion_id}, '_assertion1', 'the assertion id';
    is $id->{session_index}, '_sess1', 'the session index';
    is_deeply $id->{attributes}{email}, ['jo@example.com'],
        'a single attribute value is still an arrayref';
    is_deeply $id->{attributes}{groups}, ['staff', 'eng'],
        'a multi-valued attribute keeps its order';
    is_deeply $id->{friendly}{'E-Mail Address'}, ['jo@example.com'],
        'friendly names are carried';
    ok $id->{raw}, 'the raw bytes are kept for an audit record';
}

# a signature on the Response instead of the Assertion also satisfies
# `either`, because a Response signature covers the Assertion inside it
{
    my $r = $idp->sign($idp->response, '_response1');
    ok verify_ok($r), 'a Response-level signature satisfies `either`';
}

# ---- the wrapping attacks --------------------------------------------
#
# These are the reason this file exists. Each one is a document where the
# signed thing and the read thing differ, and each must be refused.

{
    # A signed assertion for one account, plus an unsigned one for
    # another. The verifier must not accept the unsigned one, and must
    # not accept the document at all: there is not exactly one Assertion.
    my ($second) = $idp->response(name_id => 'admin@example.com',
                                  assertion_id => '_assertion2')
                        =~ m{(<saml:Assertion.*?</saml:Assertion>)}s;
    ok $second, 'built a second assertion for the wrapping attempt';
    my $x = $idp->sign($idp->response(second_assertion => $second),
                       '_assertion1');
    my $err = verify_err($x);
    isa_ok $err, 'Punk::SAML::Error', 'two assertions';
    is $err->{code}, 'xml_shape', '  ... refused as a shape error';
}

{
    # The same attack with the ids left equal never reaches the verifier
    # at all: File::Raw::XML refuses a duplicate ID at parse, because
    # "which element does #id name" is the whole of the wrapping attack
    # and a parser that answered would be answering for the attacker.
    my ($dup) = $idp->response =~ m{(<saml:Assertion.*?</saml:Assertion>)}s;
    my $x = $idp->response(second_assertion => $dup);
    my $err = verify_err($x);
    isa_ok $err, 'Punk::SAML::Error', 'two elements with one ID';
    is $err->{code}, 'xml_parse',
        '  ... is refused at parse, before any verification';
}

{
    # The signature's Reference names a different element than the one it
    # is a child of. This is the pointer comparison.
    my $x = $idp->sign($idp->response, '_assertion1', ref_uri => '#_response1');
    my $err = verify_err($x);
    isa_ok $err, 'Punk::SAML::Error', 'a Reference naming another element';
    is $err->{code}, 'bad_signature', '  ... is bad_signature';
    like $err->{message}, qr/other than the one the Signature is a child of/,
        '  ... and says exactly that';
}

{
    # A signature that is not a direct child. Placed inside Subject, it
    # must not count, and the Assertion must then be unsigned.
    my $x = $idp->response;
    my $sig = $idp->sign($idp->response, '_assertion1');
    ($sig) = $sig =~ m{(<ds:Signature.*?</ds:Signature>)}s;
    $x =~ s{(<saml:Subject>)}{$1$sig}s;
    my $err = verify_err($x);
    isa_ok $err, 'Punk::SAML::Error', 'a Signature inside Subject';
    is $err->{code}, 'no_signature',
        '  ... does not count, so the document is unsigned';
}

{
    # A second Reference. Exactly one is required: a second one is how a
    # signature is made to appear to cover more than it does.
    my $x = $idp->sign($idp->response, '_assertion1',
        second_reference => '<ds:Reference URI="#_response1">'
            . '<ds:Transforms><ds:Transform Algorithm="'
            . $FakeIdP::ENV . '"/></ds:Transforms>'
            . '<ds:DigestMethod Algorithm="' . $FakeIdP::SHA256 . '"/>'
            . '<ds:DigestValue>AA==</ds:DigestValue></ds:Reference>');
    my $err = verify_err($x);
    isa_ok $err, 'Punk::SAML::Error', 'a second Reference';
    is $err->{code}, 'bad_signature', '  ... is bad_signature';
}

# ---- the algorithm and transform rules -------------------------------

{
    my $x = $idp->sign($idp->response, '_assertion1',
        c14n_alg => 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315');
    my $err = verify_err($x);
    is $err->{code}, 'bad_signature', 'inclusive c14n is refused';
    like $err->{message}, qr/not exclusive c14n/, '  ... by name';
}

{
    my $x = $idp->sign($idp->response, '_assertion1',
        sig_alg => 'http://www.w3.org/2000/09/xmldsig#rsa-sha1');
    is verify_err($x)->{code}, 'alg_refused', 'rsa-sha1 is refused';
}

{
    my $x = $idp->sign($idp->response, '_assertion1',
        transform2 => 'http://www.w3.org/TR/1999/REC-xpath-19991116');
    my $err = verify_err($x);
    is $err->{code}, 'bad_signature', 'an XPath transform is refused';
    like $err->{message}, qr/XPath, XSLT/,
        '  ... and the message says why those are the ones named';
}

{
    my $x = $idp->sign($idp->response, '_assertion1', transform1 => $FakeIdP::EXC);
    is verify_err($x)->{code}, 'bad_signature',
        'the first transform must be enveloped-signature';
}

{
    my $x = $idp->sign($idp->response, '_assertion1',
        dig_alg => 'http://www.w3.org/2000/09/xmldsig#sha1');
    is verify_err($x)->{code}, 'alg_refused',
        'a SHA-1 digest is refused without allow_sha1';
    ok verify_ok($x, allow_sha1 => 1),
        'and accepted with it, because the digest side is the less harmful one';
}

# ---- the cryptography itself -----------------------------------------

{
    my $x = $idp->sign($idp->response, '_assertion1', digest => 'AAAA');
    is verify_err($x)->{code}, 'bad_digest', 'a wrong digest is caught';
}

{
    my $x = $idp->sign($idp->response, '_assertion1',
        sigval => MIME::Base64::encode_base64("\x00" x 256, ''));
    is verify_err($x)->{code}, 'bad_signature', 'a wrong signature is caught';
}

{
    # the right shape, the wrong key
    my $other = FakeIdP->new;
    my $err = verify_err($signed, certs => $other->certs);
    is $err->{code}, 'bad_signature', 'another key does not verify';
}

{
    my $err = verify_err($signed, certs => []);
    is $err->{code}, 'no_key', 'no configured key is its own code';
}

# the tampered body: the signature is intact, the content is not
{
    (my $x = $signed) =~ s/jo\@example\.com/admin\@example.com/;
    is verify_err($x)->{code}, 'bad_digest',
        'editing the signed element breaks the digest';
}

done_testing();
