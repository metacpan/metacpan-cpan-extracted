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

my $idp = FakeIdP->new;
my %base = (
    idp            => 'okta',
    entity_id      => $idp->sp_entity,
    idp_entity_id  => $idp->entity_id,
    acs_url        => $idp->acs,
    certs          => $idp->certs,
    in_response_to => '_flow1',
);

sub signed { $idp->sign($idp->response(@_), '_assertion1') }
sub err {
    my ($xml, %o) = @_;
    local $@;
    eval { Punk::SAML::Response->verify($xml, %base, %o) };
    return $@;
}
sub ok_verify {
    my ($xml, %o) = @_;
    return scalar eval { Punk::SAML::Response->verify($xml, %base, %o) };
}

ok ok_verify(signed()), 'the control still verifies';

# ---- one test per code -----------------------------------------------

is err('not xml at all')->{code}, 'xml_parse', 'xml_parse';

{
    my $e = err('<foo/>');
    is $e->{code}, 'xml_shape', 'xml_shape: the root is not samlp:Response';
}

is err(signed(version => '1.1'))->{code}, 'xml_shape',
    'xml_shape: Version is not 2.0';

{
    my $e = err(signed(status => 'urn:oasis:names:tc:SAML:2.0:status:Requester',
                       status_message => 'ACS URL mismatch'));
    is $e->{code}, 'status', 'status';
    like $e->{message}, qr/Requester/, '  ... carries the code';
    like $e->{message}, qr/ACS URL mismatch/, '  ... and the StatusMessage';
}

{
    my $x = $idp->response;
    $x =~ s{(<saml:Assertion)}{<saml:EncryptedAssertion xmlns:saml="$FakeIdP::NS_A"/>$1};
    my $e = err($x);
    is $e->{code}, 'encrypted_assertion', 'encrypted_assertion';
    like $e->{message}, qr/Turn assertion encryption off/,
        '  ... names the setting to change, because the fix is at their end';
}

# no Assertion to sign, so this one is the unsigned document: the shape
# check runs before the signature check, which is the order the whole
# file is built on
is err($idp->response(no_assertion => 1))->{code}, 'xml_shape',
    'xml_shape: no Assertion, caught before the signature check';

is err($idp->response)->{code}, 'no_signature', 'no_signature';

# require_signed
{
    my $on_assertion = signed();
    my $on_response  = $idp->sign($idp->response, '_response1');
    ok ok_verify($on_assertion, require_signed => 'assertion'),
        'require_signed assertion, satisfied';
    is err($on_response, require_signed => 'assertion')->{code},
        'no_signature', 'require_signed assertion, not satisfied';
    ok ok_verify($on_response, require_signed => 'response'),
        'require_signed response, satisfied';
    is err($on_assertion, require_signed => 'both')->{code},
        'no_signature', 'require_signed both needs both';
    my $x = $idp->sign($idp->sign($idp->response, '_assertion1'), '_response1');
    ok ok_verify($x, require_signed => 'both'),
        'require_signed both, satisfied by signing each';
}

is err(signed(issuer => 'https://elsewhere/'))->{code}, 'unknown_issuer',
    'unknown_issuer';

is err(signed(destination => 'https://elsewhere/acs'))->{code},
    'bad_destination', 'bad_destination';

is err(signed(), now => time - 3600)->{code}, 'not_yet_valid',
    'not_yet_valid';

is err(signed(), now => time + 3600)->{code}, 'expired', 'expired';

# skew reaches both edges
ok ok_verify(signed(now => time - 30)), 'a small clock difference is tolerated';

is err(signed(audience => 'https://someone-else/'))->{code}, 'bad_audience',
    'bad_audience';

is err(signed(recipient => 'https://elsewhere/acs'))->{code},
    'bad_destination', 'a wrong Recipient is refused';

is err(signed(in_response_to => '_other'))->{code}, 'bad_in_response_to',
    'bad_in_response_to: a different request';

is err(signed(in_response_to => undef))->{code}, 'bad_in_response_to',
    'bad_in_response_to: nothing answered, but a login was started';

# unsolicited
{
    my $x = signed(in_response_to => undef);
    my $e = err($x, in_response_to => undef);
    is $e->{code}, 'unsolicited', 'unsolicited when no flow and no allowance';
    like $e->{message}, qr/allow_idp_initiated is off/, '  ... says which option';
    ok ok_verify($x, in_response_to => undef, allow_idp_initiated => 1),
        'and allowed when the deployment has decided to';
}

# a Response that answers a request we have no record of
is err(signed(), in_response_to => undef)->{code}, 'bad_in_response_to',
    'a Response answering an unknown request is refused';

is err(signed(no_authn => 1))->{code}, 'xml_shape', 'no AuthnStatement';

is err(signed(), seen => sub { 1 })->{code}, 'replay', 'replay';
ok ok_verify(signed(), seen => sub { 0 }), 'and not when it is unseen';

# the replay callback gets the assertion id
{
    my $got;
    ok_verify(signed(), seen => sub { $got = $_[0]; 0 });
    is $got, '_assertion1', 'the replay store is asked about the assertion id';
}

# a timestamp we cannot read is refused, never ignored: every one of them
# gates the login.
#
# The fixture is broken BEFORE it is signed. Editing a signed document
# gives bad_digest instead, which is the correct answer and the reason the
# order in psaml_response.h is what it is: nothing the signature protects
# is read until the signature has been proven. The first attempt at this
# test asserted bad_datetime on an edited signed document and was wrong
# about which check should fire.
{
    my $x = $idp->response;
    $x =~ s/NotOnOrAfter="[^"]+"/NotOnOrAfter="whenever"/;
    is err($idp->sign($x, '_assertion1'))->{code}, 'bad_datetime',
        'bad_datetime';

    my $y = signed();
    $y =~ s/NotOnOrAfter="[^"]+"/NotOnOrAfter="whenever"/;
    is err($y)->{code}, 'bad_digest',
        'and editing it after signing is caught as a digest failure first';
}

# ---- attributes -------------------------------------------------------

{
    # the same Name twice is MERGED, not overwritten: several providers
    # send a multi-valued attribute that way, and taking the last would
    # silently drop a group
    my $attrs = '<saml:AttributeStatement>'
        . '<saml:Attribute Name="groups"><saml:AttributeValue>a</saml:AttributeValue></saml:Attribute>'
        . '</saml:AttributeStatement>'
        . '<saml:AttributeStatement>'
        . '<saml:Attribute Name="groups"><saml:AttributeValue>b</saml:AttributeValue></saml:Attribute>'
        . '</saml:AttributeStatement>';
    my $id = ok_verify(signed(attributes => $attrs));
    is_deeply $id->{attributes}{groups}, ['a', 'b'],
        'a repeated Name merges rather than overwrites';
}

{
    my $attrs = '<saml:AttributeStatement>'
        . '<saml:Attribute Name="empty"><saml:AttributeValue></saml:AttributeValue></saml:Attribute>'
        . '</saml:AttributeStatement>';
    my $id = ok_verify(signed(attributes => $attrs));
    is_deeply $id->{attributes}{empty}, [''],
        'an empty value is kept as an empty string, so the count is right';
}

# an Attribute carrying no values at all is not the same as one carrying
# an empty value, and it does not appear: `exists` on the name is a
# question the caller can ask and get a useful answer to
{
    my $attrs = '<saml:AttributeStatement>'
        . '<saml:Attribute Name="novals"/>'
        . '</saml:AttributeStatement>';
    my $id = ok_verify(signed(attributes => $attrs));
    ok !exists $id->{attributes}{novals},
        'an Attribute with no values does not appear at all';
}

# an Attribute with no Name is dropped rather than keyed under the empty
# string, which nothing could look up on purpose
{
    my $attrs = '<saml:AttributeStatement>'
        . '<saml:Attribute><saml:AttributeValue>x</saml:AttributeValue></saml:Attribute>'
        . '</saml:AttributeStatement>';
    my $id = ok_verify(signed(attributes => $attrs));
    is_deeply $id->{attributes}, {}, 'an Attribute with no Name is dropped';
}

# no AttributeStatement at all still gives a hash, never undef: every
# caller dereferences this and none of them should have to test first
{
    my $id = ok_verify(signed(attributes => ''));
    is_deeply $id->{attributes}, {}, 'no AttributeStatement gives an empty hash';
    is_deeply $id->{friendly},   {}, '  ... and so does the friendly index';
}

# TWO ATTRIBUTES MAY SHARE A FRIENDLY NAME, and then `friendly` merges
# them. FriendlyName is a display label the provider is free to repeat -
# Name is the identifier - so this is the provider's doing and not
# something to refuse. It is asserted here because it is a trap: authorise
# on `attributes`, which is keyed by Name, and never on `friendly`.
{
    my $attrs = '<saml:AttributeStatement>'
        . '<saml:Attribute Name="a" FriendlyName="F"><saml:AttributeValue>1</saml:AttributeValue></saml:Attribute>'
        . '<saml:Attribute Name="b" FriendlyName="F"><saml:AttributeValue>2</saml:AttributeValue></saml:Attribute>'
        . '</saml:AttributeStatement>';
    my $id = ok_verify(signed(attributes => $attrs));
    is_deeply $id->{attributes}{a}, ['1'], 'Name keeps the two apart';
    is_deeply $id->{attributes}{b}, ['2'], '  ... both of them';
    is_deeply $id->{friendly}{F}, ['1', '2'],
        'while a shared FriendlyName merges, which is why it is not an identifier';
}

done_testing();
