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
use FakeIdP ();

# Signature wrapping, whole.
#
# Every one of these is a document where the element the signature covers
# and the element the reader takes are not the same element. That is the
# entire family of attacks, and it is the reason this distribution parses
# and verifies rather than pattern-matching, so the cases belong in one
# table somebody can read top to bottom.
#
# Five of them were found in t/06-signature.t as the signature rules were
# built, and they are repeated here rather than cross-referenced. A table
# of wrapping attacks with holes in it that say "see another file" is not
# a table anybody can check a release against.
#
# Each case asserts the CODE, never the message: the code is the
# interface, and a refusal for the wrong reason is the bug this file
# exists to find.

my $idp = FakeIdP->new;
my %base = (
    idp            => 'okta',
    entity_id      => $idp->sp_entity,
    idp_entity_id  => $idp->entity_id,
    acs_url        => $idp->acs,
    certs          => $idp->certs,
    in_response_to => '_flow1',
);

sub err {
    my ($xml, %o) = @_;
    local $@;
    my $r = eval { Punk::SAML::Response->verify($xml, %base, %o) };
    return $@ ? $@ : undef;
}

# The positive control. Without it every assertion below would also pass
# against a verify() that threw on everything it was handed.
{
    my $ok = eval {
        Punk::SAML::Response->verify($idp->sign($idp->response, '_assertion1'),
                                     %base) };
    ok $ok, 'the control verifies, so the refusals below mean something'
        or diag $@;
}

# an Assertion element, lifted out of a Response, for use as a wrapper's
# payload
sub assertion_of {
    my ($xml) = @_;
    my ($a) = $xml =~ m{(<saml:Assertion.*?</saml:Assertion>)}s;
    return $a;
}

# ---- 1: a second, unsigned Assertion AFTER the signed one -------------

{
    my $second = assertion_of($idp->response(name_id      => 'admin@example.com',
                                             assertion_id => '_assertion2'));
    my $x = $idp->sign($idp->response(second_assertion => $second),
                       '_assertion1');
    is err($x)->{code}, 'xml_shape',
        'a second Assertion after the signed one';
}

# ---- 2: a second Assertion BEFORE it ----------------------------------
#
# Position is the variable. A reader that takes the first Assertion and a
# signer that signed the second disagree, and this is the arrangement that
# exploits it.

{
    my $first = assertion_of($idp->response(name_id      => 'admin@example.com',
                                            assertion_id => '_assertion2'));
    my $x = $idp->sign($idp->response(first_assertion => $first),
                       '_assertion1');
    is err($x)->{code}, 'xml_shape',
        'a second Assertion before the signed one';
}

# ---- 3: the signed Assertion hidden in Extensions ---------------------
#
# The classic. The real, signed Assertion is moved somewhere the reader
# does not look, and an attacker's unsigned one takes its place. The
# document still has exactly one Assertion where an Assertion belongs, so
# the shape check passes and the SIGNATURE check is what has to catch it.

{
    my $signed  = $idp->sign($idp->response, '_assertion1');
    my $hidden  = assertion_of($signed);
    my $x = $idp->response(
        assertion_id => '_assertion2',
        name_id      => 'admin@example.com',
        extensions   => "<samlp:Extensions>$hidden</samlp:Extensions>",
    );
    # the fixture must really carry the signature it is hiding, or this
    # case degrades into "an unsigned document is unsigned" and proves
    # nothing about where the verifier looks
    like $x, qr/ds:Signature/,
        'the fixture really does carry the signed Assertion, out of the way';
    is err($x)->{code}, 'no_signature',
        'the signed Assertion moved into Extensions leaves the document unsigned';
}

# ---- 4: a Reference naming the OTHER assertion's ID -------------------

{
    my $second = assertion_of($idp->response(name_id      => 'admin@example.com',
                                             assertion_id => '_assertion2'));
    my $x = $idp->sign($idp->response(second_assertion => $second),
                       '_assertion1', ref_uri => '#_assertion2');
    # the shape check runs first and there are two Assertions, so that is
    # the code. It is pinned rather than left open: this document is
    # refused for a reason, and if the reason ever changes somebody should
    # have to look at why.
    is err($x)->{code}, 'xml_shape',
        'a Reference naming the other assertion never reaches the crypto';
}

# the same idea without the second assertion, so the pointer comparison is
# the only thing that can catch it
{
    my $x = $idp->sign($idp->response, '_assertion1', ref_uri => '#_response1');
    is err($x)->{code}, 'bad_signature',
        'a Reference naming an element the Signature is not a child of';
}

# ---- 5: two elements sharing the signed ID ----------------------------
#
# Refused at parse: "which element does #_assertion1 name" is the whole of
# the attack, and a parser that picked one would be picking for the
# attacker.

{
    my $dup = assertion_of($idp->response);
    is err($idp->response(second_assertion => $dup))->{code}, 'xml_parse',
        'two elements sharing one ID';
}

# ---- 6: a Reference with an empty URI ---------------------------------
#
# An empty URI means "the whole document" in XML-DSig. This dist requires
# a Reference that names the element the Signature is a child of, so the
# empty form is not a shorthand it accepts.

{
    my $x = $idp->sign($idp->response, '_assertion1', ref_uri => '');
    is err($x)->{code}, 'bad_signature', 'a Reference with an empty URI';
}

# ---- 7: two Reference elements ----------------------------------------

{
    my $x = $idp->sign($idp->response, '_assertion1',
        second_reference => '<ds:Reference URI="#_response1">'
            . '<ds:Transforms><ds:Transform Algorithm="'
            . $FakeIdP::ENV . '"/></ds:Transforms>'
            . '<ds:DigestMethod Algorithm="' . $FakeIdP::SHA256 . '"/>'
            . '<ds:DigestValue>AA==</ds:DigestValue></ds:Reference>');
    is err($x)->{code}, 'bad_signature', 'two Reference elements';
}

# ---- 8: an XPath Transform --------------------------------------------
#
# An arbitrary XPath in the transform chain lets the signer choose what
# the signature covers after the fact, which is wrapping with the
# attacker's own selector.

{
    my $x = $idp->sign($idp->response, '_assertion1',
        transform2 => 'http://www.w3.org/TR/1999/REC-xpath-19991116');
    is err($x)->{code}, 'bad_signature', 'an XPath Transform';
}

# ---- 9: a Signature placed as a grandchild ----------------------------

{
    my $sig = $idp->sign($idp->response, '_assertion1');
    ($sig) = $sig =~ m{(<ds:Signature.*?</ds:Signature>)}s;
    my $x = $idp->response;
    $x =~ s{(<saml:Subject>)}{$1$sig}s;
    is err($x)->{code}, 'no_signature',
        'a Signature that is not a direct child does not count';
}

# ---- 10: a signed Response with the Assertion swapped after signing ----

{
    my $x = $idp->sign($idp->response, '_response1');
    my $other = assertion_of($idp->response(name_id => 'admin@example.com'));
    $x =~ s{<saml:Assertion.*?</saml:Assertion>}{$other}s;
    is err($x)->{code}, 'bad_digest',
        'swapping the Assertion under a Response signature breaks the digest';
}

# ---- 11: the KeyInfo replaced with the attacker's own certificate ------
#
# The document is entirely self-consistent: the attacker signed it with
# their key and put their certificate in KeyInfo, so anything that took
# the key from the document would verify it happily. Every key this dist
# tries is one the deployer configured, and this is the test that says so.

{
    my $attacker = FakeIdP->new;
    my $x = $attacker->sign(
        $attacker->response(name_id => 'admin@example.com'),
        '_assertion1', key_info => $attacker->pub);

    # the attacker's document really is valid against the attacker's key,
    # so the refusal below is about WHOSE key, not about a broken fixture
    ok scalar(eval { Punk::SAML::Response->verify($x, %base,
                                                  certs => $attacker->certs) }),
        'the attacker signed a document that verifies against their own key';

    is err($x)->{code}, 'bad_signature',
        'and KeyInfo does not persuade the verifier to use it';
}

# ---- 12: an Assertion from a different provider, valid there ----------
#
# The Response is from the configured provider. The Assertion inside it
# was minted by another. This is why Issuer is checked on the Assertion
# and not only on the Response.

{
    my $x = $idp->sign($idp->response(assertion_issuer => 'https://other.example/entity'),
                       '_assertion1');
    is err($x)->{code}, 'unknown_issuer',
        q{an Assertion whose own Issuer is somebody else};
}

done_testing();
